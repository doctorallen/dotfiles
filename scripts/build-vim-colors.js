#!/usr/bin/env node
// Builds the Vim colorscheme in .vim/colors/ from its Esper Themes original, so
// Vim and VS Code agree on what a color is.
//
// The themes are read from the extension's built JSON. Every Esper theme has
// the same token rules under the same names, with only the palette differing,
// so a color is looked up by its rule name ("Strings", "Storage types") and
// attached to the Vim highlight groups that mean the same thing.
//
// Usage: node scripts/build-vim-colors.js [themes-dir]
//
// Without an argument the themes come from ~/projects/esper-themes/themes,
// or failing that from the newest esper-themes extension VS Code has installed.

const fs = require("fs");
const os = require("os");
const path = require("path");

const OUT = path.join(__dirname, "..", ".vim", "colors");

// The Esper themes to build, by their VS Code label. Any of the others works
// here too ("LCARS", "Bluey Night"): add its name and run the script.
const THEMES = ["Helix", "LCARS"];

function findThemes() {
  if (process.argv[2]) return path.resolve(process.argv[2]);
  const source = path.join(os.homedir(), "projects", "esper-themes", "themes");
  if (fs.existsSync(source)) return source;
  const extensions = path.join(os.homedir(), ".vscode", "extensions");
  const installed = fs.existsSync(extensions)
    ? fs
        .readdirSync(extensions)
        .filter((name) => name.startsWith("esperinnovations.esper-themes-"))
        .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
    : [];
  if (!installed.length) {
    throw new Error("Esper Themes not found: pass the themes directory");
  }
  return path.join(extensions, installed[installed.length - 1], "themes");
}

// ---- color math -----------------------------------------------------------

function parse(hex) {
  let h = hex.replace("#", "");
  if (h.length === 3 || h.length === 4) h = [...h].map((c) => c + c).join("");
  const n = (i) => parseInt(h.slice(i, i + 2), 16);
  return { r: n(0), g: n(2), b: n(4), a: h.length === 8 ? n(6) / 255 : 1 };
}

function toHex({ r, g, b }) {
  const p = (v) => Math.round(v).toString(16).padStart(2, "0");
  return `#${p(r)}${p(g)}${p(b)}`.toUpperCase();
}

// Vim has no alpha, so a translucent VS Code color becomes the opaque color it
// produces over the surface it sits on.
function over(hex, surface, alpha) {
  const top = parse(hex);
  const under = parse(surface);
  const a = alpha === undefined ? top.a : alpha;
  const mix = (k) => top[k] * a + under[k] * (1 - a);
  return toHex({ r: mix("r"), g: mix("g"), b: mix("b") });
}

function luminance(hex) {
  const c = parse(hex);
  const lin = (v) => {
    const s = v / 255;
    return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

function contrast(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

// The text color that reads best on a filled surface.
function textOn(surface, candidates) {
  return candidates.reduce((best, c) =>
    contrast(c, surface) > contrast(best, surface) ? c : best
  );
}

// Nearest of the 240 fixed xterm colors (16-255), for terminals without
// true color. The first 16 are skipped because terminals remap them.
const XTERM = [];
const CUBE = [0, 95, 135, 175, 215, 255];
for (let i = 0; i < 216; i++) {
  XTERM.push({
    n: 16 + i,
    r: CUBE[Math.floor(i / 36)],
    g: CUBE[Math.floor(i / 6) % 6],
    b: CUBE[i % 6],
  });
}
for (let i = 0; i < 24; i++) {
  const v = 8 + i * 10;
  XTERM.push({ n: 232 + i, r: v, g: v, b: v });
}
function xterm(hex) {
  const c = parse(hex);
  let best = XTERM[0];
  let bestDistance = Infinity;
  for (const x of XTERM) {
    const d = (x.r - c.r) ** 2 + (x.g - c.g) ** 2 + (x.b - c.b) ** 2;
    if (d < bestDistance) [best, bestDistance] = [x, d];
  }
  return best.n;
}

// ---- theme to highlight groups --------------------------------------------

function slug(name) {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, "-");
}

function build(theme) {
  const ui = theme.colors;
  const bg = over(ui["editor.background"], "#000000");
  const fg = over(ui["editor.foreground"], bg);
  // A workbench color, flattened onto the editor unless another surface is given.
  const color = (key, surface = bg) => {
    if (!ui[key]) throw new Error(`${theme.name}: no ${key}`);
    return over(ui[key], surface);
  };
  const rules = new Map(theme.tokenColors.map((r) => [r.name, r.settings]));
  // A token rule by name, as { fg, style }.
  const token = (name) => {
    const settings = rules.get(name);
    if (!settings) throw new Error(`${theme.name}: no token rule "${name}"`);
    const style = (settings.fontStyle || "")
      .split(/\s+/)
      .filter((s) => ["bold", "italic", "underline", "strikethrough"].includes(s))
      .join(",");
    return { fg: over(settings.foreground, bg), style };
  };

  const lines = [];
  const hi = (group, { fg: f, bg: b, style, sp } = {}) => {
    const parts = [
      `guifg=${f || "NONE"}`,
      `guibg=${b || "NONE"}`,
      `gui=${style || "NONE"}`,
      `ctermfg=${f ? xterm(f) : "NONE"}`,
      `ctermbg=${b ? xterm(b) : "NONE"}`,
      // Terminals draw an undercurl as a plain underline at best.
      `cterm=${(style || "NONE").replace("undercurl", "underline")}`,
    ];
    if (sp) parts.push(`guisp=${sp}`);
    lines.push(`hi ${group.padEnd(22)} ${parts.join(" ")}`);
  };
  const link = (to, ...groups) => {
    for (const group of groups) lines.push(`hi! link ${group.padEnd(26)} ${to}`);
  };
  const section = (title) => lines.push("", `" ${title}`);

  const error = color("editorError.foreground");
  const warning = color("editorWarning.foreground");
  const info = color("editorInfo.foreground");
  const accent = color("focusBorder");
  const lineHighlight = color("editor.lineHighlightBackground");
  const lineNr = color("editorLineNumber.foreground");
  const whitespace = color("editorWhitespace.foreground");
  const widgetBg = color("editorSuggestWidget.background");
  const widgetFg = color("editorSuggestWidget.foreground", widgetBg);
  const statusBg = color("statusBar.background");
  const statusFg = color("statusBar.foreground", statusBg);
  const added = color("editorGutter.addedBackground");
  const modified = color("editorGutter.modifiedBackground");
  const deleted = color("editorGutter.deletedBackground");
  const comment = token("Comments");

  section("Editor");
  hi("Normal", { fg, bg });
  hi("Cursor", { fg: bg, bg: color("editorCursor.foreground") });
  hi("CursorLine", { bg: lineHighlight });
  hi("CursorColumn", { bg: lineHighlight });
  // VS Code draws a ruler as a hairline; Vim fills the column, so it is kept
  // as quiet as the current-line highlight.
  hi("ColorColumn", { bg: lineHighlight });
  hi("LineNr", { fg: lineNr });
  hi("CursorLineNr", { fg: color("editorLineNumber.activeForeground"), style: "bold" });
  hi("SignColumn", { fg: lineNr });
  hi("FoldColumn", { fg: lineNr });
  hi("Folded", { fg: comment.fg, bg: lineHighlight });
  hi("VertSplit", { fg: color("editorGroup.border") });
  hi("Visual", { bg: color("editor.selectionBackground") });
  hi("Search", { bg: color("editor.findMatchHighlightBackground") });
  hi("IncSearch", { fg: bg, bg: color("editor.findMatchBorder") });
  hi("CurSearch", { fg: bg, bg: color("editor.findMatchBorder") });
  hi("MatchParen", { bg: color("editorBracketMatch.background"), style: "bold" });
  hi("NonText", { fg: over(whitespace, bg, 0.5) });
  hi("SpecialKey", { fg: over(whitespace, bg, 0.5) });
  hi("EndOfBuffer", { fg: over(whitespace, bg, 0.5) });
  hi("Conceal", { fg: whitespace });
  hi("Directory", { fg: token("Functions").fg });
  hi("Title", { fg: token("Markup headings").fg, style: "bold" });
  hi("Underlined", { fg: color("textLink.foreground"), style: "underline" });

  section("Messages");
  hi("ErrorMsg", { fg: error });
  hi("WarningMsg", { fg: warning });
  hi("MoreMsg", { fg: info });
  hi("Question", { fg: info });
  hi("ModeMsg", { fg, style: "bold" });

  section("Status line, tabs and menus");
  hi("StatusLine", { fg: statusFg, bg: statusBg });
  hi("StatusLineNC", { fg: color("tab.inactiveForeground", statusBg), bg: statusBg });
  hi("TabLine", {
    fg: color("tab.inactiveForeground"),
    bg: color("tab.inactiveBackground"),
  });
  hi("TabLineSel", {
    fg: color("tab.activeForeground"),
    bg: color("tab.activeBackground"),
    style: "bold",
  });
  hi("TabLineFill", { bg: color("editorGroupHeader.tabsBackground") });
  hi("Pmenu", { fg: widgetFg, bg: widgetBg });
  hi("PmenuSel", {
    fg: color("editorSuggestWidget.selectedForeground"),
    bg: color("editorSuggestWidget.selectedBackground"),
  });
  hi("PmenuSbar", { bg: widgetBg });
  hi("PmenuThumb", { bg: color("scrollbarSlider.background", widgetBg) });
  link("PmenuSel", "WildMenu");
  hi("QuickFixLine", { bg: color("editor.selectionBackground") });

  // The airline theme in .vim/autoload/airline/themes/esper.vim reads these,
  // so the status line follows whichever Esper colorscheme is loaded.
  section("Airline");
  const onFill = (fill) => ({ fg: textOn(fill, [bg, fg]), bg: fill, style: "bold" });
  hi("EsperModeNormal", onFill(accent));
  hi("EsperModeInsert", onFill(added));
  hi("EsperModeVisual", onFill(color("editorLineNumber.activeForeground")));
  hi("EsperModeReplace", onFill(error));
  hi("EsperStatusB", { fg: statusFg, bg: over(statusFg, statusBg, 0.14) });
  hi("EsperStatusC", { fg: statusFg, bg: statusBg });
  hi("EsperStatusInactive", {
    fg: color("tab.inactiveForeground", statusBg),
    bg: statusBg,
  });

  section("Diff, signs and diagnostics");
  hi("DiffAdd", { bg: over(added, bg, 0.16) });
  hi("DiffChange", { bg: over(modified, bg, 0.12) });
  hi("DiffText", { bg: over(modified, bg, 0.32) });
  hi("DiffDelete", { fg: over(deleted, bg, 0.6), bg: over(deleted, bg, 0.16) });
  hi("diffAdded", { fg: token("Diff inserted lines").fg });
  hi("diffRemoved", { fg: token("Diff deleted lines").fg });
  hi("diffChanged", { fg: token("Diff changed lines").fg });
  hi("EsperDiffHeader", { fg: token("Diff headers").fg });
  link("EsperDiffHeader", "diffFile", "diffNewFile", "diffOldFile", "diffIndexLine", "diffLine", "diffSubname");
  hi("GitGutterAdd", { fg: added });
  hi("GitGutterChange", { fg: modified });
  hi("GitGutterDelete", { fg: deleted });
  hi("GitGutterChangeDelete", { fg: modified });
  hi("SpellBad", { style: "undercurl", sp: error });
  hi("SpellCap", { style: "undercurl", sp: warning });
  hi("SpellRare", { style: "undercurl", sp: info });
  hi("SpellLocal", { style: "undercurl", sp: info });
  hi("ALEErrorSign", { fg: error });
  hi("ALEWarningSign", { fg: warning });
  hi("ALEInfoSign", { fg: info });
  link("SpellBad", "ALEError");
  link("SpellCap", "ALEWarning");
  link("SpellRare", "ALEInfo");

  section("Syntax");
  hi("Comment", comment);
  hi("Constant", token("Numbers and constants"));
  hi("String", token("Strings"));
  hi("Identifier", token("Variables"));
  hi("Function", token("Functions"));
  hi("Statement", token("Control keywords"));
  hi("Operator", token("Operators"));
  hi("PreProc", token("Keywords"));
  hi("Type", token("Types"));
  hi("StorageClass", token("Storage modifiers"));
  hi("Structure", token("Storage types"));
  hi("Special", token("String escapes"));
  hi("Tag", token("Tag names"));
  hi("Delimiter", { fg });
  hi("Error", token("Invalid"));
  hi("Todo", { fg: warning, style: "bold" });
  link("String", "Character");
  link("Constant", "Number", "Float", "Boolean");
  link("Statement", "Conditional", "Repeat", "Label", "Exception", "Keyword");
  link("PreProc", "Include", "Define", "Macro", "PreCondit");
  link("Structure", "Typedef");
  link("Special", "SpecialChar");
  link("Comment", "SpecialComment");
  link("Error", "Debug");

  // Roles Vim's standard groups have no name for.
  hi("EsperLangVar", token("Language variables"));
  hi("EsperProperty", token("Object properties"));
  hi("EsperParameter", token("Function parameters"));
  hi("EsperLibFunc", token("Library functions"));
  hi("EsperLibConst", token("Library constants and variables"));
  hi("EsperDecorator", token("Decorators"));
  hi("EsperRegexp", token("Regular expressions"));
  hi("EsperClass", token("Class names and library classes"));
  hi("EsperNamespace", token("Namespaces and modules"));
  hi("EsperAttr", token("Attribute names"));
  hi("EsperTagPunct", token("Tag punctuation"));

  // Vim's syntax files sort a language's words into the standard groups by
  // their own lights (JavaScript's "function" is a Type, for one). These put
  // each back under the role VS Code gives it.
  section("JavaScript and TypeScript");
  link("Structure", "jsStorageClass", "jsFunction", "jsArrowFunction", "jsClassKeyword");
  link("StorageClass", "jsExtendsKeyword", "jsAsyncKeyword");
  link("Function", "jsFuncName", "jsFuncCall", "jsClassFuncName");
  link("EsperClass", "jsClassDefinition", "jsGlobalObjects", "jsGlobalNodeObjects");
  link("EsperLangVar", "jsThis", "jsSuper");
  link("EsperProperty", "jsObjectKey", "jsObjectProp");
  link("EsperParameter", "jsFuncArgs");
  link("EsperRegexp", "jsRegexpString");
  link("EsperDecorator", "jsDecorator", "jsDecoratorFunction");
  link("Special", "jsTemplateBraces");
  link("Operator", "jsOperatorKeyword");
  link("Structure", "typescriptVariable", "typescriptFuncKeyword", "typescriptArrowFunc",
    "typescriptClassKeyword", "typescriptInterfaceKeyword", "typescriptEnumKeyword",
    "typescriptAliasKeyword");
  link("StorageClass", "typescriptAccessibilityModifier", "typescriptReadonlyModifier",
    "typescriptClassStatic", "typescriptClassExtends", "typescriptAsyncFuncKeyword",
    "typescriptAbstract");
  link("Function", "typescriptFuncName", "typescriptFunctionMethod");
  link("EsperClass", "typescriptClassName", "typescriptInterfaceName", "typescriptClassHeritage",
    "typescriptGlobal");
  link("Type", "typescriptTypeReference", "typescriptPredefinedType", "typescriptAliasDeclaration",
    "typescriptTypeParameter");
  link("Constant", "typescriptEnum");
  link("EsperLangVar", "typescriptIdentifier");
  link("EsperProperty", "typescriptObjectLabel", "typescriptMember", "typescriptProp");
  link("EsperParameter", "typescriptCall");
  link("EsperRegexp", "typescriptRegexpString");
  link("EsperDecorator", "typescriptDecorator");
  link("Special", "typescriptTemplateSB");
  link("Statement", "typescriptExport", "typescriptImport", "typescriptExportType", "typescriptImportType");
  link("Operator", "typescriptOperator", "typescriptKeywordOp");
  link("Delimiter", "typescriptBraces", "typescriptParens", "typescriptEndColons", "typescriptTypeAnnotation");

  section("PHP");
  link("Structure", "phpDefine", "phpStructure");
  link("StorageClass", "phpStorageClass");
  link("Function", "phpFunction", "phpMethod");
  link("EsperLibFunc", "phpFunctions", "phpSpecialFunction");
  link("EsperClass", "phpClass", "phpClasses", "phpStaticClasses", "phpClassExtends", "phpClassImplements");
  link("EsperNamespace", "phpUseClass", "phpUseNamespaceSeparator", "phpClassNamespaceSeparator");
  link("Type", "phpType");
  link("Identifier", "phpIdentifier", "phpVarSelector", "phpMethodsVar");
  link("Operator", "phpOperator", "phpMemberSelector", "phpRelation", "phpComparison");
  link("Statement", "phpInclude", "phpKeyword");
  link("Constant", "phpMagicConstants", "phpBoolean", "phpNullValue");
  link("Comment", "phpDocTags", "phpDocParam", "phpDocIdentifier", "phpDocNamespaceSeparator");
  link("Delimiter", "phpParent");

  section("Python");
  link("Function", "pythonFunction", "pythonFunctionCall");
  link("EsperClass", "pythonClass", "pythonExClass");
  link("EsperLibFunc", "pythonBuiltin", "pythonBuiltinFunc");
  link("Type", "pythonBuiltinType");
  link("EsperLibConst", "pythonBuiltinObj");
  link("EsperDecorator", "pythonDecorator", "pythonDecoratorName", "pythonDottedName");
  link("EsperLangVar", "pythonClassVar");
  link("Constant", "pythonNone", "pythonBoolean");
  link("Special", "pythonStrFormat", "pythonStrFormatting", "pythonBytesEscape");
  link("Operator", "pythonOperator");

  section("HTML, XML and JSX");
  link("Tag", "htmlTagName", "htmlSpecialTagName", "xmlTagName", "jsxTagName", "jsxComponentName");
  link("EsperTagPunct", "htmlTag", "htmlEndTag", "htmlTagN", "xmlTag", "xmlEndTag",
    "jsxTag", "jsxCloseTag", "jsxCloseString", "jsxPunct");
  link("EsperAttr", "htmlArg", "xmlAttrib", "jsxAttrib");
  hi("htmlString", token("HTML attribute values"));
  link("htmlString", "xmlString", "jsxString");
  link("Special", "htmlSpecialChar");
  link("Title", "htmlTitle", "htmlH1", "htmlH2", "htmlH3", "htmlH4", "htmlH5", "htmlH6");
  link("Underlined", "htmlLink");

  section("CSS, Sass and Less");
  link("Tag", "cssTagName");
  link("EsperAttr", "cssClassName", "cssClassNameDot", "cssIdentifier", "cssPseudoClassId",
    "cssPseudoClass", "scssSelectorName", "scssSelectorChar", "sassClass", "sassId", "lessClass");
  link("EsperProperty", "cssProp", "cssDefinition");
  link("EsperLibConst", "cssAttr", "cssCommonAttr");
  link("Constant", "cssColor", "cssValueNumber", "cssValueLength", "cssUnitDecorators");
  link("EsperLibFunc", "cssFunctionName");
  link("Identifier", "scssVariable", "sassVariable", "lessVariable", "cssCustomProp");
  link("Statement", "cssAtRule", "cssAtKeyword", "cssMedia", "cssInclude", "cssImportant",
    "scssInclude", "scssMixin", "scssImport", "scssExtend");
  link("Delimiter", "cssBraces", "cssNoise", "cssAttrComma");

  section("JSON and YAML");
  link("EsperProperty", "jsonKeyword");
  link("Constant", "jsonBoolean", "jsonNull", "jsonNumber");
  link("Delimiter", "jsonBraces", "jsonNoise");
  link("Tag", "yamlBlockMappingKey", "yamlFlowMappingKey", "yamlKey");
  link("String", "yamlPlainScalar", "yamlFlowString");
  link("Operator", "yamlKeyValueDelimiter", "yamlBlockCollectionItemStart");

  section("Markdown");
  hi("markdownH1", token("Markdown heading 1"));
  hi("markdownH2", token("Markdown heading 2"));
  hi("markdownH3", token("Markdown heading 3"));
  hi("markdownH4", token("Markdown deep headings"));
  link("markdownH4", "markdownH5", "markdownH6");
  hi("markdownHeadingDelimiter", token("Markdown heading markers"));
  hi("markdownBold", token("Markdown bold"));
  hi("markdownItalic", token("Markdown italic"));
  hi("markdownStrike", token("Markdown strikethrough"));
  hi("markdownBlockquote", token("Markdown block quotes"));
  hi("markdownListMarker", token("Markdown list markers"));
  hi("markdownLinkText", token("Markdown link text"));
  hi("markdownUrl", token("Markdown link destinations"));
  hi("markdownId", token("Markdown link references"));
  hi("markdownLinkDelimiter", token("Markdown link punctuation"));
  hi("markdownCode", token("Markdown inline code"));
  hi("markdownCodeBlock", token("Markdown fenced code"));
  hi("markdownCodeDelimiter", token("Markdown code fence markers"));
  hi("markdownRule", token("Markdown separators"));
  link("markdownH1", "mkdHeading", "htmlH1");
  link("markdownH2", "htmlH2");
  link("markdownH3", "htmlH3");
  link("markdownH4", "htmlH4", "htmlH5", "htmlH6");
  link("markdownHeadingDelimiter", "markdownH1Delimiter", "markdownH2Delimiter",
    "markdownH3Delimiter", "markdownH4Delimiter", "markdownH5Delimiter", "markdownH6Delimiter",
    "markdownHeadingRule", "markdownBoldDelimiter", "markdownItalicDelimiter",
    "markdownStrikeDelimiter", "mkdDelimiter");
  link("markdownBold", "htmlBold", "mkdBold");
  link("markdownItalic", "htmlItalic", "mkdItalic");
  link("markdownStrike", "htmlStrike", "mkdStrike");
  link("markdownBlockquote", "mkdBlockquote");
  link("markdownListMarker", "markdownOrderedListMarker", "mkdListItem");
  link("markdownLinkText", "mkdLink");
  link("markdownUrl", "mkdURL", "mkdInlineURL", "markdownLinkUrl");
  link("markdownId", "markdownIdDeclaration", "mkdID", "mkdLinkDef");
  link("markdownLinkDelimiter", "markdownLinkTextDelimiter", "markdownIdDelimiter");
  link("markdownCode", "mkdCode");
  link("markdownCodeDelimiter", "mkdCodeDelimiter", "mkdCodeStart", "mkdCodeEnd");
  link("markdownRule", "mkdRule");

  section("NERDTree");
  link("Directory", "NERDTreeDir", "NERDTreeDirSlash");
  hi("NERDTreeCWD", { fg: accent, style: "bold" });
  link("LineNr", "NERDTreeOpenable", "NERDTreeClosable");
  link("Comment", "NERDTreeHelp");
  link("Function", "NERDTreeExecFile");

  const name = slug(theme.name);
  const header = [
    `" ${theme.name}, from Esper Themes.`,
    `" Generated by scripts/build-vim-colors.js: change that, not this file.`,
    "",
    `set background=${theme.type === "light" ? "light" : "dark"}`,
    "hi clear",
    'if exists("syntax_on")',
    "  syntax reset",
    "endif",
    `let g:colors_name = "${name}"`,
  ];
  return { name, text: [...header, ...lines, ""].join("\n") };
}

const dir = findThemes();
const files = THEMES.map((name) => `${name.replace(/ /g, "-")}-color-theme.json`);
fs.mkdirSync(OUT, { recursive: true });
for (const file of files) {
  const theme = JSON.parse(fs.readFileSync(path.join(dir, file), "utf8"));
  const { name, text } = build(theme);
  fs.writeFileSync(path.join(OUT, `${name}.vim`), text);
  console.log(`${name}.vim`);
}
console.log(`built from ${dir}`);
