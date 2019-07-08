<?php

return PhpCsFixer\Config::create()
    ->setRules(array(
        '@PSR2' => true,
        'binary_operator_spaces' => array(
            'align_double_arrow' => true,
        ),
    ));
