<?php

/**
 * Where we let people see what is going on under the hood.
 *
 * Whilst the .htaccess should show the PHP as text/plain (and does on my localhost),
 * my live server is running PHP as a CGI-module and as such the .htaccess rules
 * don’t work. Here we simply print the requested code to screen.
 *
 */

require_once 'shared.php';

//this is also to work around PHP as CGI
ini_set("highlight.comment", "#008000");
ini_set("highlight.default", "#0000FF");
ini_set("highlight.keyword", "#3C4C72");
ini_set("highlight.string", "#000080");

$requested = (
preg_match(
    '/^\.htaccess|(?:\.(?!\.)|\/(?!_)|[-a-z0-9_])+\.(php|rem|sh)$/i',
    //trying to view self?
    @$_GET['file'] ? $_GET['file'] : '/.system/view-source.php', $_
) ? $_[0] : false
) or errorPage(
    'malformed_request.rem', 'Error: Malformed Request', array('URL' => '?file=path/to/script.php')
);

if(!isset($_[1])) {
    $_[1] = '';
}

switch ($_[1]) {
    case 'php':
        $html = str_replace(
        // retain _real_ tabs. 8 spaces *is not* the same as a tab-stop, grrr
        // pretty print using PHP’s built in syntax highlighter
            '§' . '§', "\t", highlight_string(
                trim(str_replace("\t", '§' . '§', file_get_contents(APP_ROOT . $requested))), true
            )
        );
        break;

    case 'rem': // find the permalink location
        $article     = pathinfo($requested, PATHINFO_FILENAME);
        $index_array = getIndex();
        $xyz         = preg_grep("/\|$article$/", $index_array);
        $index       = reset($xyz);
        if ($index) {
            $article_metadata = explode('|', $index);
            $article_primarytag = array_slice($article_metadata, 1, 1);
            $type = reset($article_primarytag);
            if ($requested != "$type/$article.rem") {
                header('Location: http://' . APP_HOST . "/$type/$article.rem", true, 301);
                die();
            }
        }

    default:
        $html = htmlspecialchars(file_get_contents(APP_ROOT . $requested), ENT_NOQUOTES, 'UTF-8');
}

die(
template_tags(
    template_load('view-source.html'), array(
        'TITLE'  => pathinfo($requested, PATHINFO_BASENAME),
        'HEADER' => $_[1] == 'rem' ? template_load('view-source.rem.html') : '',
        'CODE'   => $html
    )
)
);
