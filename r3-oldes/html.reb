Rebol [
    Title: "HTML Unpacker/Decoder"
    Author: "Christopher Ross-Gill"
    Date: 20-Aug-2025
    Version: 0.3.0
    File: %html.reb

    Purpose: "HTML unpacker/decoder for Rebol 3"

    Home: http://ross-gill.com/page/HTML_and_Rebol
    Rights: https://opensource.org/licenses/Apache-2.0

    Type: module
    Name: rgchris.html
    Exports: [
        html decode-reference load-markup load-html
    ]

    Needs: [
        r3:rgchris:dom
    ]

    History: [
        20-Aug-2025 0.3.0
        "Lexer to PULL model; revisions to spec, refactoring"

        28-Aug-2017 0.2.1
        "Working Adoption Agency algorithm"

        21-Aug-2017 0.2.0
        "Working Tree Creation (with caveats)"

        24-Jul-2017
        0.1.0 "Initial Version"
    ]
]


html: #[]
; module namespace

html/reference: context [
    elements: #[
        "html" [
            <a>
            <abbr>
            <address>
            <applet>
            <area>
            <article>
            <aside>
            <audio>
            <b>
            <base>
            <basefont>
            <bgsound>
            <big>
            <blockquote>
            <body>
            <br>
            <button>
            <caption>
            <center>
            <code>
            <col>
            <colgroup>
            <dd>
            <details>
            <dialog>
            <dir>
            <div>
            <dl>
            <dt>
            <em>
            <embed>
            <fieldset>
            <figcaption>
            <figure>
            <font>
            <footer>
            <form>
            <frame>
            <frameset>
            <h1>
            <h2>
            <h3>
            <h4>
            <h5>
            <h6>
            <head>
            <header>
            <hgroup>
            <hr>
            <html>
            <i>
            <iframe>
            <image>
            <img>
            <input>
            <isindex>
            <keygen>
            <label>
            <legend>
            <li>
            <link>
            <listing>
            <main>
            <marquee>
            <math>
            <meta>
            <nav>
            <nobr>
            <noembed>
            <noframes>
            <noscript>
            <object>
            <ol>
            <optgroup>
            <option>
            <p>
            <param>
            <plaintext>
            <pre>
            <rb>
            <rp>
            <rtc>
            <ruby>
            <s>
            <script>
            <section>
            <select>
            <small>
            <source>
            <span>
            <strike>
            <strong>
            <style>
            <sub>
            <summary>
            <sup>
            <svg>
            <table>
            <tbody>
            <td>
            <template>
            <textarea>
            <tfoot>
            <th>
            <thead>
            <time>
            <title>
            <tr>
            <track>
            <tt>
            <u>
            <ul>
            <var>
            <video>
            <wbr>
            <xmp>
            <bdi>
            <bdo>
            <canvas>
            <cite>
            <data>
            <datalist>
            <del>
            <dfn>
            <ins>
            <kbd>
            <legend>
            <map>
            <mark>
            <menu>
            <menuitem>
            <meter>
            <output>
            <picture>
            <progress>
            <q>
            <rt>
            <samp>
            <slot>
        ]

        "svg" [
            <a>
            <altGlyph>
            <altGlyphDef>
            <altGlyphItem>
            <animate>
            <animateColor>
            <animateMotion>
            <animateTransform>
            <audio>
            <canvas>
            <circle>
            <clipPath>
            <color-profile>
            <cursor>
            <defs>
            <desc>
            <discard>
            <ellipse>
            <feBlend>
            <feColorMatrix>
            <feComponentTransfer>
            <feComposite>
            <feConvolveMatrix>
            <feDiffuseLighting>
            <feDisplacementMap>
            <feDistantLight>
            <feDropShadow>
            <feFlood>
            <feFuncA>
            <feFuncB>
            <feFuncG>
            <feFuncR>
            <feGaussianBlur>
            <feImage>
            <feMerge>
            <feMergeNode>
            <feMorphology>
            <feOffset>
            <fePointLight>
            <feSpecularLighting>
            <feSpotLight>
            <feTile>
            <feTurbulence>
            <filter>
            <font>
            <font-face>
            <font-face-format>
            <font-face-name>
            <font-face-src>
            <font-face-uri>
            <foreignObject>
            <g>
            <glyph>
            <glyphRef>
            <hatch>
            <hatchpath>
            <hkern>
            <iframe>
            <image>
            <line>
            <linearGradient>
            <marker>
            <mask>
            <mesh>
            <meshgradient>
            <meshpatch>
            <meshrow>
            <metadata>
            <missing-glyph>
            <mpath>
            <path>
            <pattern>
            <polygon>
            <polyline>
            <radialGradient>
            <rect>
            <script>
            <set>
            <solidcolor>
            <stop>
            <style>
            <svg>
            <switch>
            <symbol>
            <text>
            <textPath>
            <title>
            <tref>
            <tspan>
            <unknown>
            <use>
            <video>
            <view>
            <vkern>
        ]

        "mathml" [
            <annotation>
            <annotation-xml>
            <maction>
            <maligngroup>
            <malignmark>
            <math>
            <menclose>
            <merror>
            <mfenced>
            <mfrac>
            <mglyph>
            <mi>
            <mlabeledtr>
            <mlongdiv>
            <mmultiscripts>
            <mn>
            <mo>
            <mover>
            <mpadded>
            <mphantom>
            <mroot>
            <mrow>
            <ms>
            <mscarries>
            <mscarry>
            <msgroup>
            <msline>
            <mspace>
            <msqrt>
            <msrow>
            <mstack>
            <mstyle>
            <msub>
            <msubsup>
            <msup>
            <mtable>
            <mtd>
            <mtext>
            <mtr>
            <munder>
            <munderover>
            <semantics>
        ]

        "self-closing" [
            <area>
            <base>
            <br>
            <col>
            <embed>
            <hr>
            <img>
            <input>
            <link>
            <meta>
            <param>
            <source>
            <track>
            <wbr>
        ]
    ]

    attributes: #[
        "html" [
            "accept" "accept-charset" "accesskey" "action" "align" "alt" "async" "autocomplete"
            "autofocus" "autoplay" "autosave" "bgcolor" "border" "buffered" "challenge" "charset"
            "checked" "cite" "class" "code" "codebase" "color" "cols" "colspan"
            "content" "contenteditable" "contextmenu" "controls" "coords" "crossorigin" "data" "datetime"
            "default" "defer" "dir" "dirname" "disabled" "download" "draggable" "dropzone"
            "enctype" "for" "form" "formaction" "headers" "height" "hidden" "high"
            "href" "hreflang" "http-equiv" "icon" "id" "integrity" "ismap" "itemprop"
            "keytype" "kind" "label" "lang" "language" "list" "loop" "low"
            "manifest" "max" "maxlength" "minlength" "media" "method" "min" "multiple"
            "muted" "name" "novalidate" "open" "optimum" "pattern" "ping" "placeholder"
            "poster" "preload" "radiogroup" "readonly" "rel" "required" "reversed" "rows"
            "rowspan" "sandbox" "scope" "scoped" "seamless" "selected" "shape" "size"
            "sizes" "slot" "span" "spellcheck" "src" "srcdoc" "srclang" "srcset"
            "start" "step" "style" "summary" "tabindex" "target" "title" "type"
            "usemap" "value" "width" "wrap"
        ]

        "svg" [
            "accent-height" "accumulate" "additive" "alignment-baseline" "allowReorder" "alphabetic"
            "amplitude" "arabic-form" "ascent" "attributeName" "attributeType" "autoReverse"
            "azimuth" "baseFrequency" "baseline-shift" "baseProfile" "bbox" "begin"
            "bias" "by" "calcMode" "cap-height" "class" "clip"
            "clipPathUnits" "clip-path" "clip-rule" "color" "color-interpolation" "color-interpolation-filters"
            "color-profile" "color-rendering" "contentScriptType" "contentStyleType" "cursor" "cx"
            "cy" "d" "decelerate" "descent" "diffuseConstant" "direction"
            "display" "divisor" "dominant-baseline" "dur" "dx" "dy"
            "edgeMode" "elevation" "enable-background" "end" "exponent" "externalResourcesRequired"
            "fill" "fill-opacity" "fill-rule" "filter" "filterRes" "filterUnits"
            "flood-color" "flood-opacity" "font-family" "font-size" "font-size-adjust" "font-stretch"
            "font-style" "font-variant" "font-weight" "format" "from" "fr"
            "fx" "fy" "g1" "g2" "glyph-name" "glyph-orientation-horizontal"
            "glyph-orientation-vertical" "glyphRef" "gradientTransform" "gradientUnits" "hanging" "height"
            "href" "horiz-adv-x" "horiz-origin-x" "id" "ideographic" "image-rendering"
            "in" "in2" "intercept" "k" "k1" "k2"
            "k3" "k4" "kernelMatrix" "kernelUnitLength" "kerning" "keyPoints"
            "keySplines" "keyTimes" "lang" "lengthAdjust" "letter-spacing" "lighting-color"
            "limitingConeAngle" "local" "marker-end" "marker-mid" "marker-start" "markerHeight"
            "markerUnits" "markerWidth" "mask" "maskContentUnits" "maskUnits" "mathematical"
            "max" "media" "method" "min" "mode" "name"
            "numOctaves" "offset" "onabort" "onactivate" "onbegin" "onclick"
            "onend" "onerror" "onfocusin" "onfocusout" "onload" "onmousedown"
            "onmousemove" "onmouseout" "onmouseover" "onmouseup" "onrepeat" "onresize"
            "onscroll" "onunload" "opacity" "operator" "order" "orient"
            "orientation" "origin" "overflow" "overline-position" "overline-thickness" "panose-1"
            "paint-order" "pathLength" "patternContentUnits" "patternTransform" "patternUnits" "pointer-events"
            "points" "pointsAtX" "pointsAtY" "pointsAtZ" "preserveAlpha" "preserveAspectRatio"
            "primitiveUnits" "r" "radius" "refX" "refY" "rendering-intent"
            "repeatCount" "repeatDur" "requiredExtensions" "requiredFeatures" "restart" "result"
            "rotate" "rx" "ry" "scale" "seed" "shape-rendering"
            "slope" "spacing" "specularConstant" "specularExponent" "speed" "spreadMethod"
            "startOffset" "stdDeviation" "stemh" "stemv" "stitchTiles" "stop-color"
            "stop-opacity" "strikethrough-position" "strikethrough-thickness" "string" "stroke" "stroke-dasharray"
            "stroke-dashoffset" "stroke-linecap" "stroke-linejoin" "stroke-miterlimit" "stroke-opacity" "stroke-width"
            "style" "surfaceScale" "systemLanguage" "tabindex" "tableValues" "target"
            "targetX" "targetY" "text-anchor" "text-decoration" "text-rendering" "textLength"
            "to" "transform" "type" "u1" "u2" "underline-position"
            "underline-thickness" "unicode" "unicode-bidi" "unicode-range" "units-per-em" "v-alphabetic"
            "v-hanging" "v-ideographic" "v-mathematical" "values" "version" "vert-adv-y"
            "vert-origin-x" "vert-origin-y" "viewBox" "viewTarget" "visibility" "width"
            "widths" "word-spacing" "writing-mode" "x" "x-height" "x1"
            "x2" "xChannelSelector" "xlink:actuate" "xlink:arcrole" "xlink:href" "xlink:role"
            "xlink:show" "xlink:title" "xlink:type" "xml:base" "xml:lang" "xml:space"
            "y" "y1" "y2" "yChannelSelector" "z" "zoomAndPan"
        ]

        "mathml" [
            "accent" "accentunder" "actiontype" "align" "alignmentscope" "altimg" "altimg-width"
            "altimg-height" "altimg-valign" "alttext" "bevelled" "charalign" "close" "columnalign"
            "columnlines" "columnspacing" "columnspan" "columnwidth" "crossout" "decimalpoint" "denomalign"
            "depth" "dir" "display" "displaystyle" "edge" "equalcolumns" "equalrows"
            "fence" "form" "frame" "framespacing" "groupalign" "height" "href"
            "id" "indentalign" "indentalignfirst" "indentalignlast" "indentshift" "indentshiftfirst" "indentshiftlast"
            "indenttarget" "infixlinebreakstyle" "largeop" "length" "linebreak" "linebreakmultchar" "linebreakstyle"
            "lineleading" "linethickness" "location" "longdivstyle" "lspace" "lquote" "mathbackground"
            "mathcolor" "mathsize" "mathvariant" "maxsize" "minlabelspacing" "minsize" "movablelimits"
            "notation" "numalign" "open" "overflow" "position" "rowalign" "rowlines"
            "rowspacing" "rowspan" "rspace" "rquote" "scriptlevel" "scriptminsize" "scriptsizemultiplier"
            "selection" "separator" "separators" "shift" "side" "src" "stackalign"
            "stretchy" "subscriptshift" "supscriptshift" "symmetric" "voffset" "width" "xlink:href"
            "xmlns"
        ]
    ]

    entities: #[
        "standard" #[
            "Aacute;" #{C381} "aacute;" #{C3A1} "Abreve;" #{C482} "abreve;" #{C483} "ac;" #{E288BE}
            "acd;" #{E288BF} "acE;" #{E288BECCB3} "Acirc;" #{C382} "acirc;" #{C3A2} "acute;" #{C2B4}
            "Acy;" #{D090} "acy;" #{D0B0} "AElig;" #{C386} "aelig;" #{C3A6} "af;" #{E281A1}
            "Afr;" #{F09D9484} "afr;" #{F09D949E} "Agrave;" #{C380} "agrave;" #{C3A0} "alefsym;" #{E284B5}
            "aleph;" #{E284B5} "Alpha;" #{CE91} "alpha;" #{CEB1} "Amacr;" #{C480} "amacr;" #{C481}
            "amalg;" #{E2A8BF} "amp;" #{26} "AMP;" #{26} "andand;" #{E2A995} "And;" #{E2A993}
            "and;" #{E288A7} "andd;" #{E2A99C} "andslope;" #{E2A998} "andv;" #{E2A99A} "ang;" #{E288A0}
            "ange;" #{E2A6A4} "angle;" #{E288A0} "angmsdaa;" #{E2A6A8} "angmsdab;" #{E2A6A9} "angmsdac;" #{E2A6AA}
            "angmsdad;" #{E2A6AB} "angmsdae;" #{E2A6AC} "angmsdaf;" #{E2A6AD} "angmsdag;" #{E2A6AE} "angmsdah;" #{E2A6AF}
            "angmsd;" #{E288A1} "angrt;" #{E2889F} "angrtvb;" #{E28ABE} "angrtvbd;" #{E2A69D} "angsph;" #{E288A2}
            "angst;" #{C385} "angzarr;" #{E28DBC} "Aogon;" #{C484} "aogon;" #{C485} "Aopf;" #{F09D94B8}
            "aopf;" #{F09D9592} "apacir;" #{E2A9AF} "ap;" #{E28988} "apE;" #{E2A9B0} "ape;" #{E2898A}
            "apid;" #{E2898B} "apos;" #{27} "ApplyFunction;" #{E281A1} "approx;" #{E28988} "approxeq;" #{E2898A}
            "Aring;" #{C385} "aring;" #{C3A5} "Ascr;" #{F09D929C} "ascr;" #{F09D92B6} "Assign;" #{E28994}
            "ast;" #{2A} "asymp;" #{E28988} "asympeq;" #{E2898D} "Atilde;" #{C383} "atilde;" #{C3A3}
            "Auml;" #{C384} "auml;" #{C3A4} "awconint;" #{E288B3} "awint;" #{E2A891} "backcong;" #{E2898C}
            "backepsilon;" #{CFB6} "backprime;" #{E280B5} "backsim;" #{E288BD} "backsimeq;" #{E28B8D} "Backslash;" #{E28896}
            "Barv;" #{E2ABA7} "barvee;" #{E28ABD} "barwed;" #{E28C85} "Barwed;" #{E28C86} "barwedge;" #{E28C85}
            "bbrk;" #{E28EB5} "bbrktbrk;" #{E28EB6} "bcong;" #{E2898C} "Bcy;" #{D091} "bcy;" #{D0B1}
            "bdquo;" #{E2809E} "becaus;" #{E288B5} "because;" #{E288B5} "Because;" #{E288B5} "bemptyv;" #{E2A6B0}
            "bepsi;" #{CFB6} "bernou;" #{E284AC} "Bernoullis;" #{E284AC} "Beta;" #{CE92} "beta;" #{CEB2}
            "beth;" #{E284B6} "between;" #{E289AC} "Bfr;" #{F09D9485} "bfr;" #{F09D949F} "bigcap;" #{E28B82}
            "bigcirc;" #{E297AF} "bigcup;" #{E28B83} "bigodot;" #{E2A880} "bigoplus;" #{E2A881} "bigotimes;" #{E2A882}
            "bigsqcup;" #{E2A886} "bigstar;" #{E29885} "bigtriangledown;" #{E296BD} "bigtriangleup;" #{E296B3} "biguplus;" #{E2A884}
            "bigvee;" #{E28B81} "bigwedge;" #{E28B80} "bkarow;" #{E2A48D} "blacklozenge;" #{E2A7AB} "blacksquare;" #{E296AA}
            "blacktriangle;" #{E296B4} "blacktriangledown;" #{E296BE} "blacktriangleleft;" #{E29782} "blacktriangleright;" #{E296B8} "blank;" #{E290A3}
            "blk12;" #{E29692} "blk14;" #{E29691} "blk34;" #{E29693} "block;" #{E29688} "bne;" #{3DE283A5}
            "bnequiv;" #{E289A1E283A5} "bNot;" #{E2ABAD} "bnot;" #{E28C90} "Bopf;" #{F09D94B9} "bopf;" #{F09D9593}
            "bot;" #{E28AA5} "bottom;" #{E28AA5} "bowtie;" #{E28B88} "boxbox;" #{E2A789} "boxdl;" #{E29490}
            "boxdL;" #{E29595} "boxDl;" #{E29596} "boxDL;" #{E29597} "boxdr;" #{E2948C} "boxdR;" #{E29592}
            "boxDr;" #{E29593} "boxDR;" #{E29594} "boxh;" #{E29480} "boxH;" #{E29590} "boxhd;" #{E294AC}
            "boxHd;" #{E295A4} "boxhD;" #{E295A5} "boxHD;" #{E295A6} "boxhu;" #{E294B4} "boxHu;" #{E295A7}
            "boxhU;" #{E295A8} "boxHU;" #{E295A9} "boxminus;" #{E28A9F} "boxplus;" #{E28A9E} "boxtimes;" #{E28AA0}
            "boxul;" #{E29498} "boxuL;" #{E2959B} "boxUl;" #{E2959C} "boxUL;" #{E2959D} "boxur;" #{E29494}
            "boxuR;" #{E29598} "boxUr;" #{E29599} "boxUR;" #{E2959A} "boxv;" #{E29482} "boxV;" #{E29591}
            "boxvh;" #{E294BC} "boxvH;" #{E295AA} "boxVh;" #{E295AB} "boxVH;" #{E295AC} "boxvl;" #{E294A4}
            "boxvL;" #{E295A1} "boxVl;" #{E295A2} "boxVL;" #{E295A3} "boxvr;" #{E2949C} "boxvR;" #{E2959E}
            "boxVr;" #{E2959F} "boxVR;" #{E295A0} "bprime;" #{E280B5} "breve;" #{CB98} "Breve;" #{CB98}
            "brvbar;" #{C2A6} "bscr;" #{F09D92B7} "Bscr;" #{E284AC} "bsemi;" #{E2818F} "bsim;" #{E288BD}
            "bsime;" #{E28B8D} "bsolb;" #{E2A785} "bsol;" #{5C} "bsolhsub;" #{E29F88} "bull;" #{E280A2}
            "bullet;" #{E280A2} "bump;" #{E2898E} "bumpE;" #{E2AAAE} "bumpe;" #{E2898F} "Bumpeq;" #{E2898E}
            "bumpeq;" #{E2898F} "Cacute;" #{C486} "cacute;" #{C487} "capand;" #{E2A984} "capbrcup;" #{E2A989}
            "capcap;" #{E2A98B} "cap;" #{E288A9} "Cap;" #{E28B92} "capcup;" #{E2A987} "capdot;" #{E2A980}
            "CapitalDifferentialD;" #{E28585} "caps;" #{E288A9EFB880} "caret;" #{E28181} "caron;" #{CB87} "Cayleys;" #{E284AD}
            "ccaps;" #{E2A98D} "Ccaron;" #{C48C} "ccaron;" #{C48D} "Ccedil;" #{C387} "ccedil;" #{C3A7}
            "Ccirc;" #{C488} "ccirc;" #{C489} "Cconint;" #{E288B0} "ccups;" #{E2A98C} "ccupssm;" #{E2A990}
            "Cdot;" #{C48A} "cdot;" #{C48B} "cedil;" #{C2B8} "Cedilla;" #{C2B8} "cemptyv;" #{E2A6B2}
            "cent;" #{C2A2} "centerdot;" #{C2B7} "CenterDot;" #{C2B7} "cfr;" #{F09D94A0} "Cfr;" #{E284AD}
            "CHcy;" #{D0A7} "chcy;" #{D187} "check;" #{E29C93} "checkmark;" #{E29C93} "Chi;" #{CEA7}
            "chi;" #{CF87} "circ;" #{CB86} "circeq;" #{E28997} "circlearrowleft;" #{E286BA} "circlearrowright;" #{E286BB}
            "circledast;" #{E28A9B} "circledcirc;" #{E28A9A} "circleddash;" #{E28A9D} "CircleDot;" #{E28A99} "circledR;" #{C2AE}
            "circledS;" #{E29388} "CircleMinus;" #{E28A96} "CirclePlus;" #{E28A95} "CircleTimes;" #{E28A97} "cir;" #{E2978B}
            "cirE;" #{E2A783} "cire;" #{E28997} "cirfnint;" #{E2A890} "cirmid;" #{E2ABAF} "cirscir;" #{E2A782}
            "ClockwiseContourIntegral;" #{E288B2} "CloseCurlyDoubleQuote;" #{E2809D} "CloseCurlyQuote;" #{E28099} "clubs;" #{E299A3} "clubsuit;" #{E299A3}
            "colon;" #{3A} "Colon;" #{E288B7} "Colone;" #{E2A9B4} "colone;" #{E28994} "coloneq;" #{E28994}
            "comma;" #{2C} "commat;" #{40} "comp;" #{E28881} "compfn;" #{E28898} "complement;" #{E28881}
            "complexes;" #{E28482} "cong;" #{E28985} "congdot;" #{E2A9AD} "Congruent;" #{E289A1} "conint;" #{E288AE}
            "Conint;" #{E288AF} "ContourIntegral;" #{E288AE} "copf;" #{F09D9594} "Copf;" #{E28482} "coprod;" #{E28890}
            "Coproduct;" #{E28890} "copy;" #{C2A9} "COPY;" #{C2A9} "copysr;" #{E28497} "CounterClockwiseContourIntegral;" #{E288B3}
            "crarr;" #{E286B5} "cross;" #{E29C97} "Cross;" #{E2A8AF} "Cscr;" #{F09D929E} "cscr;" #{F09D92B8}
            "csub;" #{E2AB8F} "csube;" #{E2AB91} "csup;" #{E2AB90} "csupe;" #{E2AB92} "ctdot;" #{E28BAF}
            "cudarrl;" #{E2A4B8} "cudarrr;" #{E2A4B5} "cuepr;" #{E28B9E} "cuesc;" #{E28B9F} "cularr;" #{E286B6}
            "cularrp;" #{E2A4BD} "cupbrcap;" #{E2A988} "cupcap;" #{E2A986} "CupCap;" #{E2898D} "cup;" #{E288AA}
            "Cup;" #{E28B93} "cupcup;" #{E2A98A} "cupdot;" #{E28A8D} "cupor;" #{E2A985} "cups;" #{E288AAEFB880}
            "curarr;" #{E286B7} "curarrm;" #{E2A4BC} "curlyeqprec;" #{E28B9E} "curlyeqsucc;" #{E28B9F} "curlyvee;" #{E28B8E}
            "curlywedge;" #{E28B8F} "curren;" #{C2A4} "curvearrowleft;" #{E286B6} "curvearrowright;" #{E286B7} "cuvee;" #{E28B8E}
            "cuwed;" #{E28B8F} "cwconint;" #{E288B2} "cwint;" #{E288B1} "cylcty;" #{E28CAD} "dagger;" #{E280A0}
            "Dagger;" #{E280A1} "daleth;" #{E284B8} "darr;" #{E28693} "Darr;" #{E286A1} "dArr;" #{E28793}
            "dash;" #{E28090} "Dashv;" #{E2ABA4} "dashv;" #{E28AA3} "dbkarow;" #{E2A48F} "dblac;" #{CB9D}
            "Dcaron;" #{C48E} "dcaron;" #{C48F} "Dcy;" #{D094} "dcy;" #{D0B4} "ddagger;" #{E280A1}
            "ddarr;" #{E2878A} "DD;" #{E28585} "dd;" #{E28586} "DDotrahd;" #{E2A491} "ddotseq;" #{E2A9B7}
            "deg;" #{C2B0} "Del;" #{E28887} "Delta;" #{CE94} "delta;" #{CEB4} "demptyv;" #{E2A6B1}
            "dfisht;" #{E2A5BF} "Dfr;" #{F09D9487} "dfr;" #{F09D94A1} "dHar;" #{E2A5A5} "dharl;" #{E28783}
            "dharr;" #{E28782} "DiacriticalAcute;" #{C2B4} "DiacriticalDot;" #{CB99} "DiacriticalDoubleAcute;" #{CB9D} "DiacriticalGrave;" #{60}
            "DiacriticalTilde;" #{CB9C} "diam;" #{E28B84} "diamond;" #{E28B84} "Diamond;" #{E28B84} "diamondsuit;" #{E299A6}
            "diams;" #{E299A6} "die;" #{C2A8} "DifferentialD;" #{E28586} "digamma;" #{CF9D} "disin;" #{E28BB2}
            "div;" #{C3B7} "divide;" #{C3B7} "divideontimes;" #{E28B87} "divonx;" #{E28B87} "DJcy;" #{D082}
            "djcy;" #{D192} "dlcorn;" #{E28C9E} "dlcrop;" #{E28C8D} "dollar;" #{24} "Dopf;" #{F09D94BB}
            "dopf;" #{F09D9595} "Dot;" #{C2A8} "dot;" #{CB99} "DotDot;" #{E2839C} "doteq;" #{E28990}
            "doteqdot;" #{E28991} "DotEqual;" #{E28990} "dotminus;" #{E288B8} "dotplus;" #{E28894} "dotsquare;" #{E28AA1}
            "doublebarwedge;" #{E28C86} "DoubleContourIntegral;" #{E288AF} "DoubleDot;" #{C2A8} "DoubleDownArrow;" #{E28793} "DoubleLeftArrow;" #{E28790}
            "DoubleLeftRightArrow;" #{E28794} "DoubleLeftTee;" #{E2ABA4} "DoubleLongLeftArrow;" #{E29FB8} "DoubleLongLeftRightArrow;" #{E29FBA} "DoubleLongRightArrow;" #{E29FB9}
            "DoubleRightArrow;" #{E28792} "DoubleRightTee;" #{E28AA8} "DoubleUpArrow;" #{E28791} "DoubleUpDownArrow;" #{E28795} "DoubleVerticalBar;" #{E288A5}
            "DownArrowBar;" #{E2A493} "downarrow;" #{E28693} "DownArrow;" #{E28693} "Downarrow;" #{E28793} "DownArrowUpArrow;" #{E287B5}
            "DownBreve;" #{CC91} "downdownarrows;" #{E2878A} "downharpoonleft;" #{E28783} "downharpoonright;" #{E28782} "DownLeftRightVector;" #{E2A590}
            "DownLeftTeeVector;" #{E2A59E} "DownLeftVectorBar;" #{E2A596} "DownLeftVector;" #{E286BD} "DownRightTeeVector;" #{E2A59F} "DownRightVectorBar;" #{E2A597}
            "DownRightVector;" #{E28781} "DownTeeArrow;" #{E286A7} "DownTee;" #{E28AA4} "drbkarow;" #{E2A490} "drcorn;" #{E28C9F}
            "drcrop;" #{E28C8C} "Dscr;" #{F09D929F} "dscr;" #{F09D92B9} "DScy;" #{D085} "dscy;" #{D195}
            "dsol;" #{E2A7B6} "Dstrok;" #{C490} "dstrok;" #{C491} "dtdot;" #{E28BB1} "dtri;" #{E296BF}
            "dtrif;" #{E296BE} "duarr;" #{E287B5} "duhar;" #{E2A5AF} "dwangle;" #{E2A6A6} "DZcy;" #{D08F}
            "dzcy;" #{D19F} "dzigrarr;" #{E29FBF} "Eacute;" #{C389} "eacute;" #{C3A9} "easter;" #{E2A9AE}
            "Ecaron;" #{C49A} "ecaron;" #{C49B} "Ecirc;" #{C38A} "ecirc;" #{C3AA} "ecir;" #{E28996}
            "ecolon;" #{E28995} "Ecy;" #{D0AD} "ecy;" #{D18D} "eDDot;" #{E2A9B7} "Edot;" #{C496}
            "edot;" #{C497} "eDot;" #{E28991} "ee;" #{E28587} "efDot;" #{E28992} "Efr;" #{F09D9488}
            "efr;" #{F09D94A2} "eg;" #{E2AA9A} "Egrave;" #{C388} "egrave;" #{C3A8} "egs;" #{E2AA96}
            "egsdot;" #{E2AA98} "el;" #{E2AA99} "Element;" #{E28888} "elinters;" #{E28FA7} "ell;" #{E28493}
            "els;" #{E2AA95} "elsdot;" #{E2AA97} "Emacr;" #{C492} "emacr;" #{C493} "empty;" #{E28885}
            "emptyset;" #{E28885} "EmptySmallSquare;" #{E297BB} "emptyv;" #{E28885} "EmptyVerySmallSquare;" #{E296AB} "emsp13;" #{E28084}
            "emsp14;" #{E28085} "emsp;" #{E28083} "ENG;" #{C58A} "eng;" #{C58B} "ensp;" #{E28082}
            "Eogon;" #{C498} "eogon;" #{C499} "Eopf;" #{F09D94BC} "eopf;" #{F09D9596} "epar;" #{E28B95}
            "eparsl;" #{E2A7A3} "eplus;" #{E2A9B1} "epsi;" #{CEB5} "Epsilon;" #{CE95} "epsilon;" #{CEB5}
            "epsiv;" #{CFB5} "eqcirc;" #{E28996} "eqcolon;" #{E28995} "eqsim;" #{E28982} "eqslantgtr;" #{E2AA96}
            "eqslantless;" #{E2AA95} "Equal;" #{E2A9B5} "equals;" #{3D} "EqualTilde;" #{E28982} "equest;" #{E2899F}
            "Equilibrium;" #{E2878C} "equiv;" #{E289A1} "equivDD;" #{E2A9B8} "eqvparsl;" #{E2A7A5} "erarr;" #{E2A5B1}
            "erDot;" #{E28993} "escr;" #{E284AF} "Escr;" #{E284B0} "esdot;" #{E28990} "Esim;" #{E2A9B3}
            "esim;" #{E28982} "Eta;" #{CE97} "eta;" #{CEB7} "ETH;" #{C390} "eth;" #{C3B0}
            "Euml;" #{C38B} "euml;" #{C3AB} "euro;" #{E282AC} "excl;" #{21} "exist;" #{E28883}
            "Exists;" #{E28883} "expectation;" #{E284B0} "exponentiale;" #{E28587} "ExponentialE;" #{E28587} "fallingdotseq;" #{E28992}
            "Fcy;" #{D0A4} "fcy;" #{D184} "female;" #{E29980} "ffilig;" #{EFAC83} "fflig;" #{EFAC80}
            "ffllig;" #{EFAC84} "Ffr;" #{F09D9489} "ffr;" #{F09D94A3} "filig;" #{EFAC81} "FilledSmallSquare;" #{E297BC}
            "FilledVerySmallSquare;" #{E296AA} "fjlig;" #{666A} "flat;" #{E299AD} "fllig;" #{EFAC82} "fltns;" #{E296B1}
            "fnof;" #{C692} "Fopf;" #{F09D94BD} "fopf;" #{F09D9597} "forall;" #{E28880} "ForAll;" #{E28880}
            "fork;" #{E28B94} "forkv;" #{E2AB99} "Fouriertrf;" #{E284B1} "fpartint;" #{E2A88D} "frac12;" #{C2BD}
            "frac13;" #{E28593} "frac14;" #{C2BC} "frac15;" #{E28595} "frac16;" #{E28599} "frac18;" #{E2859B}
            "frac23;" #{E28594} "frac25;" #{E28596} "frac34;" #{C2BE} "frac35;" #{E28597} "frac38;" #{E2859C}
            "frac45;" #{E28598} "frac56;" #{E2859A} "frac58;" #{E2859D} "frac78;" #{E2859E} "frasl;" #{E28184}
            "frown;" #{E28CA2} "fscr;" #{F09D92BB} "Fscr;" #{E284B1} "gacute;" #{C7B5} "Gamma;" #{CE93}
            "gamma;" #{CEB3} "Gammad;" #{CF9C} "gammad;" #{CF9D} "gap;" #{E2AA86} "Gbreve;" #{C49E}
            "gbreve;" #{C49F} "Gcedil;" #{C4A2} "Gcirc;" #{C49C} "gcirc;" #{C49D} "Gcy;" #{D093}
            "gcy;" #{D0B3} "Gdot;" #{C4A0} "gdot;" #{C4A1} "ge;" #{E289A5} "gE;" #{E289A7}
            "gEl;" #{E2AA8C} "gel;" #{E28B9B} "geq;" #{E289A5} "geqq;" #{E289A7} "geqslant;" #{E2A9BE}
            "gescc;" #{E2AAA9} "ges;" #{E2A9BE} "gesdot;" #{E2AA80} "gesdoto;" #{E2AA82} "gesdotol;" #{E2AA84}
            "gesl;" #{E28B9BEFB880} "gesles;" #{E2AA94} "Gfr;" #{F09D948A} "gfr;" #{F09D94A4} "gg;" #{E289AB}
            "Gg;" #{E28B99} "ggg;" #{E28B99} "gimel;" #{E284B7} "GJcy;" #{D083} "gjcy;" #{D193}
            "gla;" #{E2AAA5} "gl;" #{E289B7} "glE;" #{E2AA92} "glj;" #{E2AAA4} "gnap;" #{E2AA8A}
            "gnapprox;" #{E2AA8A} "gne;" #{E2AA88} "gnE;" #{E289A9} "gneq;" #{E2AA88} "gneqq;" #{E289A9}
            "gnsim;" #{E28BA7} "Gopf;" #{F09D94BE} "gopf;" #{F09D9598} "grave;" #{60} "GreaterEqual;" #{E289A5}
            "GreaterEqualLess;" #{E28B9B} "GreaterFullEqual;" #{E289A7} "GreaterGreater;" #{E2AAA2} "GreaterLess;" #{E289B7} "GreaterSlantEqual;" #{E2A9BE}
            "GreaterTilde;" #{E289B3} "Gscr;" #{F09D92A2} "gscr;" #{E2848A} "gsim;" #{E289B3} "gsime;" #{E2AA8E}
            "gsiml;" #{E2AA90} "gtcc;" #{E2AAA7} "gtcir;" #{E2A9BA} "gt;" #{3E} "GT;" #{3E}
            "Gt;" #{E289AB} "gtdot;" #{E28B97} "gtlPar;" #{E2A695} "gtquest;" #{E2A9BC} "gtrapprox;" #{E2AA86}
            "gtrarr;" #{E2A5B8} "gtrdot;" #{E28B97} "gtreqless;" #{E28B9B} "gtreqqless;" #{E2AA8C} "gtrless;" #{E289B7}
            "gtrsim;" #{E289B3} "gvertneqq;" #{E289A9EFB880} "gvnE;" #{E289A9EFB880} "Hacek;" #{CB87} "hairsp;" #{E2808A}
            "half;" #{C2BD} "hamilt;" #{E2848B} "HARDcy;" #{D0AA} "hardcy;" #{D18A} "harrcir;" #{E2A588}
            "harr;" #{E28694} "hArr;" #{E28794} "harrw;" #{E286AD} "Hat;" #{5E} "hbar;" #{E2848F}
            "Hcirc;" #{C4A4} "hcirc;" #{C4A5} "hearts;" #{E299A5} "heartsuit;" #{E299A5} "hellip;" #{E280A6}
            "hercon;" #{E28AB9} "hfr;" #{F09D94A5} "Hfr;" #{E2848C} "HilbertSpace;" #{E2848B} "hksearow;" #{E2A4A5}
            "hkswarow;" #{E2A4A6} "hoarr;" #{E287BF} "homtht;" #{E288BB} "hookleftarrow;" #{E286A9} "hookrightarrow;" #{E286AA}
            "hopf;" #{F09D9599} "Hopf;" #{E2848D} "horbar;" #{E28095} "HorizontalLine;" #{E29480} "hscr;" #{F09D92BD}
            "Hscr;" #{E2848B} "hslash;" #{E2848F} "Hstrok;" #{C4A6} "hstrok;" #{C4A7} "HumpDownHump;" #{E2898E}
            "HumpEqual;" #{E2898F} "hybull;" #{E28183} "hyphen;" #{E28090} "Iacute;" #{C38D} "iacute;" #{C3AD}
            "ic;" #{E281A3} "Icirc;" #{C38E} "icirc;" #{C3AE} "Icy;" #{D098} "icy;" #{D0B8}
            "Idot;" #{C4B0} "IEcy;" #{D095} "iecy;" #{D0B5} "iexcl;" #{C2A1} "iff;" #{E28794}
            "ifr;" #{F09D94A6} "Ifr;" #{E28491} "Igrave;" #{C38C} "igrave;" #{C3AC} "ii;" #{E28588}
            "iiiint;" #{E2A88C} "iiint;" #{E288AD} "iinfin;" #{E2A79C} "iiota;" #{E284A9} "IJlig;" #{C4B2}
            "ijlig;" #{C4B3} "Imacr;" #{C4AA} "imacr;" #{C4AB} "image;" #{E28491} "ImaginaryI;" #{E28588}
            "imagline;" #{E28490} "imagpart;" #{E28491} "imath;" #{C4B1} "Im;" #{E28491} "imof;" #{E28AB7}
            "imped;" #{C6B5} "Implies;" #{E28792} "incare;" #{E28485} "in;" #{E28888} "infin;" #{E2889E}
            "infintie;" #{E2A79D} "inodot;" #{C4B1} "intcal;" #{E28ABA} "int;" #{E288AB} "Int;" #{E288AC}
            "integers;" #{E284A4} "Integral;" #{E288AB} "intercal;" #{E28ABA} "Intersection;" #{E28B82} "intlarhk;" #{E2A897}
            "intprod;" #{E2A8BC} "InvisibleComma;" #{E281A3} "InvisibleTimes;" #{E281A2} "IOcy;" #{D081} "iocy;" #{D191}
            "Iogon;" #{C4AE} "iogon;" #{C4AF} "Iopf;" #{F09D9580} "iopf;" #{F09D959A} "Iota;" #{CE99}
            "iota;" #{CEB9} "iprod;" #{E2A8BC} "iquest;" #{C2BF} "iscr;" #{F09D92BE} "Iscr;" #{E28490}
            "isin;" #{E28888} "isindot;" #{E28BB5} "isinE;" #{E28BB9} "isins;" #{E28BB4} "isinsv;" #{E28BB3}
            "isinv;" #{E28888} "it;" #{E281A2} "Itilde;" #{C4A8} "itilde;" #{C4A9} "Iukcy;" #{D086}
            "iukcy;" #{D196} "Iuml;" #{C38F} "iuml;" #{C3AF} "Jcirc;" #{C4B4} "jcirc;" #{C4B5}
            "Jcy;" #{D099} "jcy;" #{D0B9} "Jfr;" #{F09D948D} "jfr;" #{F09D94A7} "jmath;" #{C8B7}
            "Jopf;" #{F09D9581} "jopf;" #{F09D959B} "Jscr;" #{F09D92A5} "jscr;" #{F09D92BF} "Jsercy;" #{D088}
            "jsercy;" #{D198} "Jukcy;" #{D084} "jukcy;" #{D194} "Kappa;" #{CE9A} "kappa;" #{CEBA}
            "kappav;" #{CFB0} "Kcedil;" #{C4B6} "kcedil;" #{C4B7} "Kcy;" #{D09A} "kcy;" #{D0BA}
            "Kfr;" #{F09D948E} "kfr;" #{F09D94A8} "kgreen;" #{C4B8} "KHcy;" #{D0A5} "khcy;" #{D185}
            "KJcy;" #{D08C} "kjcy;" #{D19C} "Kopf;" #{F09D9582} "kopf;" #{F09D959C} "Kscr;" #{F09D92A6}
            "kscr;" #{F09D9380} "lAarr;" #{E2879A} "Lacute;" #{C4B9} "lacute;" #{C4BA} "laemptyv;" #{E2A6B4}
            "lagran;" #{E28492} "Lambda;" #{CE9B} "lambda;" #{CEBB} "lang;" #{E29FA8} "Lang;" #{E29FAA}
            "langd;" #{E2A691} "langle;" #{E29FA8} "lap;" #{E2AA85} "Laplacetrf;" #{E28492} "laquo;" #{C2AB}
            "larrb;" #{E287A4} "larrbfs;" #{E2A49F} "larr;" #{E28690} "Larr;" #{E2869E} "lArr;" #{E28790}
            "larrfs;" #{E2A49D} "larrhk;" #{E286A9} "larrlp;" #{E286AB} "larrpl;" #{E2A4B9} "larrsim;" #{E2A5B3}
            "larrtl;" #{E286A2} "latail;" #{E2A499} "lAtail;" #{E2A49B} "lat;" #{E2AAAB} "late;" #{E2AAAD}
            "lates;" #{E2AAADEFB880} "lbarr;" #{E2A48C} "lBarr;" #{E2A48E} "lbbrk;" #{E29DB2} "lbrace;" #{7B}
            "lbrack;" #{5B} "lbrke;" #{E2A68B} "lbrksld;" #{E2A68F} "lbrkslu;" #{E2A68D} "Lcaron;" #{C4BD}
            "lcaron;" #{C4BE} "Lcedil;" #{C4BB} "lcedil;" #{C4BC} "lceil;" #{E28C88} "lcub;" #{7B}
            "Lcy;" #{D09B} "lcy;" #{D0BB} "ldca;" #{E2A4B6} "ldquo;" #{E2809C} "ldquor;" #{E2809E}
            "ldrdhar;" #{E2A5A7} "ldrushar;" #{E2A58B} "ldsh;" #{E286B2} "le;" #{E289A4} "lE;" #{E289A6}
            "LeftAngleBracket;" #{E29FA8} "LeftArrowBar;" #{E287A4} "leftarrow;" #{E28690} "LeftArrow;" #{E28690} "Leftarrow;" #{E28790}
            "LeftArrowRightArrow;" #{E28786} "leftarrowtail;" #{E286A2} "LeftCeiling;" #{E28C88} "LeftDoubleBracket;" #{E29FA6} "LeftDownTeeVector;" #{E2A5A1}
            "LeftDownVectorBar;" #{E2A599} "LeftDownVector;" #{E28783} "LeftFloor;" #{E28C8A} "leftharpoondown;" #{E286BD} "leftharpoonup;" #{E286BC}
            "leftleftarrows;" #{E28787} "leftrightarrow;" #{E28694} "LeftRightArrow;" #{E28694} "Leftrightarrow;" #{E28794} "leftrightarrows;" #{E28786}
            "leftrightharpoons;" #{E2878B} "leftrightsquigarrow;" #{E286AD} "LeftRightVector;" #{E2A58E} "LeftTeeArrow;" #{E286A4} "LeftTee;" #{E28AA3}
            "LeftTeeVector;" #{E2A59A} "leftthreetimes;" #{E28B8B} "LeftTriangleBar;" #{E2A78F} "LeftTriangle;" #{E28AB2} "LeftTriangleEqual;" #{E28AB4}
            "LeftUpDownVector;" #{E2A591} "LeftUpTeeVector;" #{E2A5A0} "LeftUpVectorBar;" #{E2A598} "LeftUpVector;" #{E286BF} "LeftVectorBar;" #{E2A592}
            "LeftVector;" #{E286BC} "lEg;" #{E2AA8B} "leg;" #{E28B9A} "leq;" #{E289A4} "leqq;" #{E289A6}
            "leqslant;" #{E2A9BD} "lescc;" #{E2AAA8} "les;" #{E2A9BD} "lesdot;" #{E2A9BF} "lesdoto;" #{E2AA81}
            "lesdotor;" #{E2AA83} "lesg;" #{E28B9AEFB880} "lesges;" #{E2AA93} "lessapprox;" #{E2AA85} "lessdot;" #{E28B96}
            "lesseqgtr;" #{E28B9A} "lesseqqgtr;" #{E2AA8B} "LessEqualGreater;" #{E28B9A} "LessFullEqual;" #{E289A6} "LessGreater;" #{E289B6}
            "lessgtr;" #{E289B6} "LessLess;" #{E2AAA1} "lesssim;" #{E289B2} "LessSlantEqual;" #{E2A9BD} "LessTilde;" #{E289B2}
            "lfisht;" #{E2A5BC} "lfloor;" #{E28C8A} "Lfr;" #{F09D948F} "lfr;" #{F09D94A9} "lg;" #{E289B6}
            "lgE;" #{E2AA91} "lHar;" #{E2A5A2} "lhard;" #{E286BD} "lharu;" #{E286BC} "lharul;" #{E2A5AA}
            "lhblk;" #{E29684} "LJcy;" #{D089} "ljcy;" #{D199} "llarr;" #{E28787} "ll;" #{E289AA}
            "Ll;" #{E28B98} "llcorner;" #{E28C9E} "Lleftarrow;" #{E2879A} "llhard;" #{E2A5AB} "lltri;" #{E297BA}
            "Lmidot;" #{C4BF} "lmidot;" #{C580} "lmoustache;" #{E28EB0} "lmoust;" #{E28EB0} "lnap;" #{E2AA89}
            "lnapprox;" #{E2AA89} "lne;" #{E2AA87} "lnE;" #{E289A8} "lneq;" #{E2AA87} "lneqq;" #{E289A8}
            "lnsim;" #{E28BA6} "loang;" #{E29FAC} "loarr;" #{E287BD} "lobrk;" #{E29FA6} "longleftarrow;" #{E29FB5}
            "LongLeftArrow;" #{E29FB5} "Longleftarrow;" #{E29FB8} "longleftrightarrow;" #{E29FB7} "LongLeftRightArrow;" #{E29FB7} "Longleftrightarrow;" #{E29FBA}
            "longmapsto;" #{E29FBC} "longrightarrow;" #{E29FB6} "LongRightArrow;" #{E29FB6} "Longrightarrow;" #{E29FB9} "looparrowleft;" #{E286AB}
            "looparrowright;" #{E286AC} "lopar;" #{E2A685} "Lopf;" #{F09D9583} "lopf;" #{F09D959D} "loplus;" #{E2A8AD}
            "lotimes;" #{E2A8B4} "lowast;" #{E28897} "lowbar;" #{5F} "LowerLeftArrow;" #{E28699} "LowerRightArrow;" #{E28698}
            "loz;" #{E2978A} "lozenge;" #{E2978A} "lozf;" #{E2A7AB} "lpar;" #{28} "lparlt;" #{E2A693}
            "lrarr;" #{E28786} "lrcorner;" #{E28C9F} "lrhar;" #{E2878B} "lrhard;" #{E2A5AD} "lrm;" #{E2808E}
            "lrtri;" #{E28ABF} "lsaquo;" #{E280B9} "lscr;" #{F09D9381} "Lscr;" #{E28492} "lsh;" #{E286B0}
            "Lsh;" #{E286B0} "lsim;" #{E289B2} "lsime;" #{E2AA8D} "lsimg;" #{E2AA8F} "lsqb;" #{5B}
            "lsquo;" #{E28098} "lsquor;" #{E2809A} "Lstrok;" #{C581} "lstrok;" #{C582} "ltcc;" #{E2AAA6}
            "ltcir;" #{E2A9B9} "lt;" #{3C} "LT;" #{3C} "Lt;" #{E289AA} "ltdot;" #{E28B96}
            "lthree;" #{E28B8B} "ltimes;" #{E28B89} "ltlarr;" #{E2A5B6} "ltquest;" #{E2A9BB} "ltri;" #{E29783}
            "ltrie;" #{E28AB4} "ltrif;" #{E29782} "ltrPar;" #{E2A696} "lurdshar;" #{E2A58A} "luruhar;" #{E2A5A6}
            "lvertneqq;" #{E289A8EFB880} "lvnE;" #{E289A8EFB880} "macr;" #{C2AF} "male;" #{E29982} "malt;" #{E29CA0}
            "maltese;" #{E29CA0} "Map;" #{E2A485} "map;" #{E286A6} "mapsto;" #{E286A6} "mapstodown;" #{E286A7}
            "mapstoleft;" #{E286A4} "mapstoup;" #{E286A5} "marker;" #{E296AE} "mcomma;" #{E2A8A9} "Mcy;" #{D09C}
            "mcy;" #{D0BC} "mdash;" #{E28094} "mDDot;" #{E288BA} "measuredangle;" #{E288A1} "MediumSpace;" #{E2819F}
            "Mellintrf;" #{E284B3} "Mfr;" #{F09D9490} "mfr;" #{F09D94AA} "mho;" #{E284A7} "micro;" #{C2B5}
            "midast;" #{2A} "midcir;" #{E2ABB0} "mid;" #{E288A3} "middot;" #{C2B7} "minusb;" #{E28A9F}
            "minus;" #{E28892} "minusd;" #{E288B8} "minusdu;" #{E2A8AA} "MinusPlus;" #{E28893} "mlcp;" #{E2AB9B}
            "mldr;" #{E280A6} "mnplus;" #{E28893} "models;" #{E28AA7} "Mopf;" #{F09D9584} "mopf;" #{F09D959E}
            "mp;" #{E28893} "mscr;" #{F09D9382} "Mscr;" #{E284B3} "mstpos;" #{E288BE} "Mu;" #{CE9C}
            "mu;" #{CEBC} "multimap;" #{E28AB8} "mumap;" #{E28AB8} "nabla;" #{E28887} "Nacute;" #{C583}
            "nacute;" #{C584} "nang;" #{E288A0E28392} "nap;" #{E28989} "napE;" #{E2A9B0CCB8} "napid;" #{E2898BCCB8}
            "napos;" #{C589} "napprox;" #{E28989} "natural;" #{E299AE} "naturals;" #{E28495} "natur;" #{E299AE}
            "nbsp;" #{C2A0} "nbump;" #{E2898ECCB8} "nbumpe;" #{E2898FCCB8} "ncap;" #{E2A983} "Ncaron;" #{C587}
            "ncaron;" #{C588} "Ncedil;" #{C585} "ncedil;" #{C586} "ncong;" #{E28987} "ncongdot;" #{E2A9ADCCB8}
            "ncup;" #{E2A982} "Ncy;" #{D09D} "ncy;" #{D0BD} "ndash;" #{E28093} "nearhk;" #{E2A4A4}
            "nearr;" #{E28697} "neArr;" #{E28797} "nearrow;" #{E28697} "ne;" #{E289A0} "nedot;" #{E28990CCB8}
            "NegativeMediumSpace;" #{E2808B} "NegativeThickSpace;" #{E2808B} "NegativeThinSpace;" #{E2808B} "NegativeVeryThinSpace;" #{E2808B} "nequiv;" #{E289A2}
            "nesear;" #{E2A4A8} "nesim;" #{E28982CCB8} "NestedGreaterGreater;" #{E289AB} "NestedLessLess;" #{E289AA} "NewLine;" #{0A}
            "nexist;" #{E28884} "nexists;" #{E28884} "Nfr;" #{F09D9491} "nfr;" #{F09D94AB} "ngE;" #{E289A7CCB8}
            "nge;" #{E289B1} "ngeq;" #{E289B1} "ngeqq;" #{E289A7CCB8} "ngeqslant;" #{E2A9BECCB8} "nges;" #{E2A9BECCB8}
            "nGg;" #{E28B99CCB8} "ngsim;" #{E289B5} "nGt;" #{E289ABE28392} "ngt;" #{E289AF} "ngtr;" #{E289AF}
            "nGtv;" #{E289ABCCB8} "nharr;" #{E286AE} "nhArr;" #{E2878E} "nhpar;" #{E2ABB2} "ni;" #{E2888B}
            "nis;" #{E28BBC} "nisd;" #{E28BBA} "niv;" #{E2888B} "NJcy;" #{D08A} "njcy;" #{D19A}
            "nlarr;" #{E2869A} "nlArr;" #{E2878D} "nldr;" #{E280A5} "nlE;" #{E289A6CCB8} "nle;" #{E289B0}
            "nleftarrow;" #{E2869A} "nLeftarrow;" #{E2878D} "nleftrightarrow;" #{E286AE} "nLeftrightarrow;" #{E2878E} "nleq;" #{E289B0}
            "nleqq;" #{E289A6CCB8} "nleqslant;" #{E2A9BDCCB8} "nles;" #{E2A9BDCCB8} "nless;" #{E289AE} "nLl;" #{E28B98CCB8}
            "nlsim;" #{E289B4} "nLt;" #{E289AAE28392} "nlt;" #{E289AE} "nltri;" #{E28BAA} "nltrie;" #{E28BAC}
            "nLtv;" #{E289AACCB8} "nmid;" #{E288A4} "NoBreak;" #{E281A0} "NonBreakingSpace;" #{C2A0} "nopf;" #{F09D959F}
            "Nopf;" #{E28495} "Not;" #{E2ABAC} "not;" #{C2AC} "NotCongruent;" #{E289A2} "NotCupCap;" #{E289AD}
            "NotDoubleVerticalBar;" #{E288A6} "NotElement;" #{E28889} "NotEqual;" #{E289A0} "NotEqualTilde;" #{E28982CCB8} "NotExists;" #{E28884}
            "NotGreater;" #{E289AF} "NotGreaterEqual;" #{E289B1} "NotGreaterFullEqual;" #{E289A7CCB8} "NotGreaterGreater;" #{E289ABCCB8} "NotGreaterLess;" #{E289B9}
            "NotGreaterSlantEqual;" #{E2A9BECCB8} "NotGreaterTilde;" #{E289B5} "NotHumpDownHump;" #{E2898ECCB8} "NotHumpEqual;" #{E2898FCCB8} "notin;" #{E28889}
            "notindot;" #{E28BB5CCB8} "notinE;" #{E28BB9CCB8} "notinva;" #{E28889} "notinvb;" #{E28BB7} "notinvc;" #{E28BB6}
            "NotLeftTriangleBar;" #{E2A78FCCB8} "NotLeftTriangle;" #{E28BAA} "NotLeftTriangleEqual;" #{E28BAC} "NotLess;" #{E289AE} "NotLessEqual;" #{E289B0}
            "NotLessGreater;" #{E289B8} "NotLessLess;" #{E289AACCB8} "NotLessSlantEqual;" #{E2A9BDCCB8} "NotLessTilde;" #{E289B4} "NotNestedGreaterGreater;" #{E2AAA2CCB8}
            "NotNestedLessLess;" #{E2AAA1CCB8} "notni;" #{E2888C} "notniva;" #{E2888C} "notnivb;" #{E28BBE} "notnivc;" #{E28BBD}
            "NotPrecedes;" #{E28A80} "NotPrecedesEqual;" #{E2AAAFCCB8} "NotPrecedesSlantEqual;" #{E28BA0} "NotReverseElement;" #{E2888C} "NotRightTriangleBar;" #{E2A790CCB8}
            "NotRightTriangle;" #{E28BAB} "NotRightTriangleEqual;" #{E28BAD} "NotSquareSubset;" #{E28A8FCCB8} "NotSquareSubsetEqual;" #{E28BA2} "NotSquareSuperset;" #{E28A90CCB8}
            "NotSquareSupersetEqual;" #{E28BA3} "NotSubset;" #{E28A82E28392} "NotSubsetEqual;" #{E28A88} "NotSucceeds;" #{E28A81} "NotSucceedsEqual;" #{E2AAB0CCB8}
            "NotSucceedsSlantEqual;" #{E28BA1} "NotSucceedsTilde;" #{E289BFCCB8} "NotSuperset;" #{E28A83E28392} "NotSupersetEqual;" #{E28A89} "NotTilde;" #{E28981}
            "NotTildeEqual;" #{E28984} "NotTildeFullEqual;" #{E28987} "NotTildeTilde;" #{E28989} "NotVerticalBar;" #{E288A4} "nparallel;" #{E288A6}
            "npar;" #{E288A6} "nparsl;" #{E2ABBDE283A5} "npart;" #{E28882CCB8} "npolint;" #{E2A894} "npr;" #{E28A80}
            "nprcue;" #{E28BA0} "nprec;" #{E28A80} "npreceq;" #{E2AAAFCCB8} "npre;" #{E2AAAFCCB8} "nrarrc;" #{E2A4B3CCB8}
            "nrarr;" #{E2869B} "nrArr;" #{E2878F} "nrarrw;" #{E2869DCCB8} "nrightarrow;" #{E2869B} "nRightarrow;" #{E2878F}
            "nrtri;" #{E28BAB} "nrtrie;" #{E28BAD} "nsc;" #{E28A81} "nsccue;" #{E28BA1} "nsce;" #{E2AAB0CCB8}
            "Nscr;" #{F09D92A9} "nscr;" #{F09D9383} "nshortmid;" #{E288A4} "nshortparallel;" #{E288A6} "nsim;" #{E28981}
            "nsime;" #{E28984} "nsimeq;" #{E28984} "nsmid;" #{E288A4} "nspar;" #{E288A6} "nsqsube;" #{E28BA2}
            "nsqsupe;" #{E28BA3} "nsub;" #{E28A84} "nsubE;" #{E2AB85CCB8} "nsube;" #{E28A88} "nsubset;" #{E28A82E28392}
            "nsubseteq;" #{E28A88} "nsubseteqq;" #{E2AB85CCB8} "nsucc;" #{E28A81} "nsucceq;" #{E2AAB0CCB8} "nsup;" #{E28A85}
            "nsupE;" #{E2AB86CCB8} "nsupe;" #{E28A89} "nsupset;" #{E28A83E28392} "nsupseteq;" #{E28A89} "nsupseteqq;" #{E2AB86CCB8}
            "ntgl;" #{E289B9} "Ntilde;" #{C391} "ntilde;" #{C3B1} "ntlg;" #{E289B8} "ntriangleleft;" #{E28BAA}
            "ntrianglelefteq;" #{E28BAC} "ntriangleright;" #{E28BAB} "ntrianglerighteq;" #{E28BAD} "Nu;" #{CE9D} "nu;" #{CEBD}
            "num;" #{23} "numero;" #{E28496} "numsp;" #{E28087} "nvap;" #{E2898DE28392} "nvdash;" #{E28AAC}
            "nvDash;" #{E28AAD} "nVdash;" #{E28AAE} "nVDash;" #{E28AAF} "nvge;" #{E289A5E28392} "nvgt;" #{3EE28392}
            "nvHarr;" #{E2A484} "nvinfin;" #{E2A79E} "nvlArr;" #{E2A482} "nvle;" #{E289A4E28392} "nvlt;" #{3CE28392}
            "nvltrie;" #{E28AB4E28392} "nvrArr;" #{E2A483} "nvrtrie;" #{E28AB5E28392} "nvsim;" #{E288BCE28392} "nwarhk;" #{E2A4A3}
            "nwarr;" #{E28696} "nwArr;" #{E28796} "nwarrow;" #{E28696} "nwnear;" #{E2A4A7} "Oacute;" #{C393}
            "oacute;" #{C3B3} "oast;" #{E28A9B} "Ocirc;" #{C394} "ocirc;" #{C3B4} "ocir;" #{E28A9A}
            "Ocy;" #{D09E} "ocy;" #{D0BE} "odash;" #{E28A9D} "Odblac;" #{C590} "odblac;" #{C591}
            "odiv;" #{E2A8B8} "odot;" #{E28A99} "odsold;" #{E2A6BC} "OElig;" #{C592} "oelig;" #{C593}
            "ofcir;" #{E2A6BF} "Ofr;" #{F09D9492} "ofr;" #{F09D94AC} "ogon;" #{CB9B} "Ograve;" #{C392}
            "ograve;" #{C3B2} "ogt;" #{E2A781} "ohbar;" #{E2A6B5} "ohm;" #{CEA9} "oint;" #{E288AE}
            "olarr;" #{E286BA} "olcir;" #{E2A6BE} "olcross;" #{E2A6BB} "oline;" #{E280BE} "olt;" #{E2A780}
            "Omacr;" #{C58C} "omacr;" #{C58D} "Omega;" #{CEA9} "omega;" #{CF89} "Omicron;" #{CE9F}
            "omicron;" #{CEBF} "omid;" #{E2A6B6} "ominus;" #{E28A96} "Oopf;" #{F09D9586} "oopf;" #{F09D95A0}
            "opar;" #{E2A6B7} "OpenCurlyDoubleQuote;" #{E2809C} "OpenCurlyQuote;" #{E28098} "operp;" #{E2A6B9} "oplus;" #{E28A95}
            "orarr;" #{E286BB} "Or;" #{E2A994} "or;" #{E288A8} "ord;" #{E2A99D} "order;" #{E284B4}
            "orderof;" #{E284B4} "ordf;" #{C2AA} "ordm;" #{C2BA} "origof;" #{E28AB6} "oror;" #{E2A996}
            "orslope;" #{E2A997} "orv;" #{E2A99B} "oS;" #{E29388} "Oscr;" #{F09D92AA} "oscr;" #{E284B4}
            "Oslash;" #{C398} "oslash;" #{C3B8} "osol;" #{E28A98} "Otilde;" #{C395} "otilde;" #{C3B5}
            "otimesas;" #{E2A8B6} "Otimes;" #{E2A8B7} "otimes;" #{E28A97} "Ouml;" #{C396} "ouml;" #{C3B6}
            "ovbar;" #{E28CBD} "OverBar;" #{E280BE} "OverBrace;" #{E28F9E} "OverBracket;" #{E28EB4} "OverParenthesis;" #{E28F9C}
            "para;" #{C2B6} "parallel;" #{E288A5} "par;" #{E288A5} "parsim;" #{E2ABB3} "parsl;" #{E2ABBD}
            "part;" #{E28882} "PartialD;" #{E28882} "Pcy;" #{D09F} "pcy;" #{D0BF} "percnt;" #{25}
            "period;" #{2E} "permil;" #{E280B0} "perp;" #{E28AA5} "pertenk;" #{E280B1} "Pfr;" #{F09D9493}
            "pfr;" #{F09D94AD} "Phi;" #{CEA6} "phi;" #{CF86} "phiv;" #{CF95} "phmmat;" #{E284B3}
            "phone;" #{E2988E} "Pi;" #{CEA0} "pi;" #{CF80} "pitchfork;" #{E28B94} "piv;" #{CF96}
            "planck;" #{E2848F} "planckh;" #{E2848E} "plankv;" #{E2848F} "plusacir;" #{E2A8A3} "plusb;" #{E28A9E}
            "pluscir;" #{E2A8A2} "plus;" #{2B} "plusdo;" #{E28894} "plusdu;" #{E2A8A5} "pluse;" #{E2A9B2}
            "PlusMinus;" #{C2B1} "plusmn;" #{C2B1} "plussim;" #{E2A8A6} "plustwo;" #{E2A8A7} "pm;" #{C2B1}
            "Poincareplane;" #{E2848C} "pointint;" #{E2A895} "popf;" #{F09D95A1} "Popf;" #{E28499} "pound;" #{C2A3}
            "prap;" #{E2AAB7} "Pr;" #{E2AABB} "pr;" #{E289BA} "prcue;" #{E289BC} "precapprox;" #{E2AAB7}
            "prec;" #{E289BA} "preccurlyeq;" #{E289BC} "Precedes;" #{E289BA} "PrecedesEqual;" #{E2AAAF} "PrecedesSlantEqual;" #{E289BC}
            "PrecedesTilde;" #{E289BE} "preceq;" #{E2AAAF} "precnapprox;" #{E2AAB9} "precneqq;" #{E2AAB5} "precnsim;" #{E28BA8}
            "pre;" #{E2AAAF} "prE;" #{E2AAB3} "precsim;" #{E289BE} "prime;" #{E280B2} "Prime;" #{E280B3}
            "primes;" #{E28499} "prnap;" #{E2AAB9} "prnE;" #{E2AAB5} "prnsim;" #{E28BA8} "prod;" #{E2888F}
            "Product;" #{E2888F} "profalar;" #{E28CAE} "profline;" #{E28C92} "profsurf;" #{E28C93} "prop;" #{E2889D}
            "Proportional;" #{E2889D} "Proportion;" #{E288B7} "propto;" #{E2889D} "prsim;" #{E289BE} "prurel;" #{E28AB0}
            "Pscr;" #{F09D92AB} "pscr;" #{F09D9385} "Psi;" #{CEA8} "psi;" #{CF88} "puncsp;" #{E28088}
            "Qfr;" #{F09D9494} "qfr;" #{F09D94AE} "qint;" #{E2A88C} "qopf;" #{F09D95A2} "Qopf;" #{E2849A}
            "qprime;" #{E28197} "Qscr;" #{F09D92AC} "qscr;" #{F09D9386} "quaternions;" #{E2848D} "quatint;" #{E2A896}
            "quest;" #{3F} "questeq;" #{E2899F} "quot;" #{22} "QUOT;" #{22} "rAarr;" #{E2879B}
            "race;" #{E288BDCCB1} "Racute;" #{C594} "racute;" #{C595} "radic;" #{E2889A} "raemptyv;" #{E2A6B3}
            "rang;" #{E29FA9} "Rang;" #{E29FAB} "rangd;" #{E2A692} "range;" #{E2A6A5} "rangle;" #{E29FA9}
            "raquo;" #{C2BB} "rarrap;" #{E2A5B5} "rarrb;" #{E287A5} "rarrbfs;" #{E2A4A0} "rarrc;" #{E2A4B3}
            "rarr;" #{E28692} "Rarr;" #{E286A0} "rArr;" #{E28792} "rarrfs;" #{E2A49E} "rarrhk;" #{E286AA}
            "rarrlp;" #{E286AC} "rarrpl;" #{E2A585} "rarrsim;" #{E2A5B4} "Rarrtl;" #{E2A496} "rarrtl;" #{E286A3}
            "rarrw;" #{E2869D} "ratail;" #{E2A49A} "rAtail;" #{E2A49C} "ratio;" #{E288B6} "rationals;" #{E2849A}
            "rbarr;" #{E2A48D} "rBarr;" #{E2A48F} "RBarr;" #{E2A490} "rbbrk;" #{E29DB3} "rbrace;" #{7D}
            "rbrack;" #{5D} "rbrke;" #{E2A68C} "rbrksld;" #{E2A68E} "rbrkslu;" #{E2A690} "Rcaron;" #{C598}
            "rcaron;" #{C599} "Rcedil;" #{C596} "rcedil;" #{C597} "rceil;" #{E28C89} "rcub;" #{7D}
            "Rcy;" #{D0A0} "rcy;" #{D180} "rdca;" #{E2A4B7} "rdldhar;" #{E2A5A9} "rdquo;" #{E2809D}
            "rdquor;" #{E2809D} "rdsh;" #{E286B3} "real;" #{E2849C} "realine;" #{E2849B} "realpart;" #{E2849C}
            "reals;" #{E2849D} "Re;" #{E2849C} "rect;" #{E296AD} "reg;" #{C2AE} "REG;" #{C2AE}
            "ReverseElement;" #{E2888B} "ReverseEquilibrium;" #{E2878B} "ReverseUpEquilibrium;" #{E2A5AF} "rfisht;" #{E2A5BD} "rfloor;" #{E28C8B}
            "rfr;" #{F09D94AF} "Rfr;" #{E2849C} "rHar;" #{E2A5A4} "rhard;" #{E28781} "rharu;" #{E28780}
            "rharul;" #{E2A5AC} "Rho;" #{CEA1} "rho;" #{CF81} "rhov;" #{CFB1} "RightAngleBracket;" #{E29FA9}
            "RightArrowBar;" #{E287A5} "rightarrow;" #{E28692} "RightArrow;" #{E28692} "Rightarrow;" #{E28792} "RightArrowLeftArrow;" #{E28784}
            "rightarrowtail;" #{E286A3} "RightCeiling;" #{E28C89} "RightDoubleBracket;" #{E29FA7} "RightDownTeeVector;" #{E2A59D} "RightDownVectorBar;" #{E2A595}
            "RightDownVector;" #{E28782} "RightFloor;" #{E28C8B} "rightharpoondown;" #{E28781} "rightharpoonup;" #{E28780} "rightleftarrows;" #{E28784}
            "rightleftharpoons;" #{E2878C} "rightrightarrows;" #{E28789} "rightsquigarrow;" #{E2869D} "RightTeeArrow;" #{E286A6} "RightTee;" #{E28AA2}
            "RightTeeVector;" #{E2A59B} "rightthreetimes;" #{E28B8C} "RightTriangleBar;" #{E2A790} "RightTriangle;" #{E28AB3} "RightTriangleEqual;" #{E28AB5}
            "RightUpDownVector;" #{E2A58F} "RightUpTeeVector;" #{E2A59C} "RightUpVectorBar;" #{E2A594} "RightUpVector;" #{E286BE} "RightVectorBar;" #{E2A593}
            "RightVector;" #{E28780} "ring;" #{CB9A} "risingdotseq;" #{E28993} "rlarr;" #{E28784} "rlhar;" #{E2878C}
            "rlm;" #{E2808F} "rmoustache;" #{E28EB1} "rmoust;" #{E28EB1} "rnmid;" #{E2ABAE} "roang;" #{E29FAD}
            "roarr;" #{E287BE} "robrk;" #{E29FA7} "ropar;" #{E2A686} "ropf;" #{F09D95A3} "Ropf;" #{E2849D}
            "roplus;" #{E2A8AE} "rotimes;" #{E2A8B5} "RoundImplies;" #{E2A5B0} "rpar;" #{29} "rpargt;" #{E2A694}
            "rppolint;" #{E2A892} "rrarr;" #{E28789} "Rrightarrow;" #{E2879B} "rsaquo;" #{E280BA} "rscr;" #{F09D9387}
            "Rscr;" #{E2849B} "rsh;" #{E286B1} "Rsh;" #{E286B1} "rsqb;" #{5D} "rsquo;" #{E28099}
            "rsquor;" #{E28099} "rthree;" #{E28B8C} "rtimes;" #{E28B8A} "rtri;" #{E296B9} "rtrie;" #{E28AB5}
            "rtrif;" #{E296B8} "rtriltri;" #{E2A78E} "RuleDelayed;" #{E2A7B4} "ruluhar;" #{E2A5A8} "rx;" #{E2849E}
            "Sacute;" #{C59A} "sacute;" #{C59B} "sbquo;" #{E2809A} "scap;" #{E2AAB8} "Scaron;" #{C5A0}
            "scaron;" #{C5A1} "Sc;" #{E2AABC} "sc;" #{E289BB} "sccue;" #{E289BD} "sce;" #{E2AAB0}
            "scE;" #{E2AAB4} "Scedil;" #{C59E} "scedil;" #{C59F} "Scirc;" #{C59C} "scirc;" #{C59D}
            "scnap;" #{E2AABA} "scnE;" #{E2AAB6} "scnsim;" #{E28BA9} "scpolint;" #{E2A893} "scsim;" #{E289BF}
            "Scy;" #{D0A1} "scy;" #{D181} "sdotb;" #{E28AA1} "sdot;" #{E28B85} "sdote;" #{E2A9A6}
            "searhk;" #{E2A4A5} "searr;" #{E28698} "seArr;" #{E28798} "searrow;" #{E28698} "sect;" #{C2A7}
            "semi;" #{3B} "seswar;" #{E2A4A9} "setminus;" #{E28896} "setmn;" #{E28896} "sext;" #{E29CB6}
            "Sfr;" #{F09D9496} "sfr;" #{F09D94B0} "sfrown;" #{E28CA2} "sharp;" #{E299AF} "SHCHcy;" #{D0A9}
            "shchcy;" #{D189} "SHcy;" #{D0A8} "shcy;" #{D188} "ShortDownArrow;" #{E28693} "ShortLeftArrow;" #{E28690}
            "shortmid;" #{E288A3} "shortparallel;" #{E288A5} "ShortRightArrow;" #{E28692} "ShortUpArrow;" #{E28691} "shy;" #{C2AD}
            "Sigma;" #{CEA3} "sigma;" #{CF83} "sigmaf;" #{CF82} "sigmav;" #{CF82} "sim;" #{E288BC}
            "simdot;" #{E2A9AA} "sime;" #{E28983} "simeq;" #{E28983} "simg;" #{E2AA9E} "simgE;" #{E2AAA0}
            "siml;" #{E2AA9D} "simlE;" #{E2AA9F} "simne;" #{E28986} "simplus;" #{E2A8A4} "simrarr;" #{E2A5B2}
            "slarr;" #{E28690} "SmallCircle;" #{E28898} "smallsetminus;" #{E28896} "smashp;" #{E2A8B3} "smeparsl;" #{E2A7A4}
            "smid;" #{E288A3} "smile;" #{E28CA3} "smt;" #{E2AAAA} "smte;" #{E2AAAC} "smtes;" #{E2AAACEFB880}
            "SOFTcy;" #{D0AC} "softcy;" #{D18C} "solbar;" #{E28CBF} "solb;" #{E2A784} "sol;" #{2F}
            "Sopf;" #{F09D958A} "sopf;" #{F09D95A4} "spades;" #{E299A0} "spadesuit;" #{E299A0} "spar;" #{E288A5}
            "sqcap;" #{E28A93} "sqcaps;" #{E28A93EFB880} "sqcup;" #{E28A94} "sqcups;" #{E28A94EFB880} "Sqrt;" #{E2889A}
            "sqsub;" #{E28A8F} "sqsube;" #{E28A91} "sqsubset;" #{E28A8F} "sqsubseteq;" #{E28A91} "sqsup;" #{E28A90}
            "sqsupe;" #{E28A92} "sqsupset;" #{E28A90} "sqsupseteq;" #{E28A92} "square;" #{E296A1} "Square;" #{E296A1}
            "SquareIntersection;" #{E28A93} "SquareSubset;" #{E28A8F} "SquareSubsetEqual;" #{E28A91} "SquareSuperset;" #{E28A90} "SquareSupersetEqual;" #{E28A92}
            "SquareUnion;" #{E28A94} "squarf;" #{E296AA} "squ;" #{E296A1} "squf;" #{E296AA} "srarr;" #{E28692}
            "Sscr;" #{F09D92AE} "sscr;" #{F09D9388} "ssetmn;" #{E28896} "ssmile;" #{E28CA3} "sstarf;" #{E28B86}
            "Star;" #{E28B86} "star;" #{E29886} "starf;" #{E29885} "straightepsilon;" #{CFB5} "straightphi;" #{CF95}
            "strns;" #{C2AF} "sub;" #{E28A82} "Sub;" #{E28B90} "subdot;" #{E2AABD} "subE;" #{E2AB85}
            "sube;" #{E28A86} "subedot;" #{E2AB83} "submult;" #{E2AB81} "subnE;" #{E2AB8B} "subne;" #{E28A8A}
            "subplus;" #{E2AABF} "subrarr;" #{E2A5B9} "subset;" #{E28A82} "Subset;" #{E28B90} "subseteq;" #{E28A86}
            "subseteqq;" #{E2AB85} "SubsetEqual;" #{E28A86} "subsetneq;" #{E28A8A} "subsetneqq;" #{E2AB8B} "subsim;" #{E2AB87}
            "subsub;" #{E2AB95} "subsup;" #{E2AB93} "succapprox;" #{E2AAB8} "succ;" #{E289BB} "succcurlyeq;" #{E289BD}
            "Succeeds;" #{E289BB} "SucceedsEqual;" #{E2AAB0} "SucceedsSlantEqual;" #{E289BD} "SucceedsTilde;" #{E289BF} "succeq;" #{E2AAB0}
            "succnapprox;" #{E2AABA} "succneqq;" #{E2AAB6} "succnsim;" #{E28BA9} "succsim;" #{E289BF} "SuchThat;" #{E2888B}
            "sum;" #{E28891} "Sum;" #{E28891} "sung;" #{E299AA} "sup1;" #{C2B9} "sup2;" #{C2B2}
            "sup3;" #{C2B3} "sup;" #{E28A83} "Sup;" #{E28B91} "supdot;" #{E2AABE} "supdsub;" #{E2AB98}
            "supE;" #{E2AB86} "supe;" #{E28A87} "supedot;" #{E2AB84} "Superset;" #{E28A83} "SupersetEqual;" #{E28A87}
            "suphsol;" #{E29F89} "suphsub;" #{E2AB97} "suplarr;" #{E2A5BB} "supmult;" #{E2AB82} "supnE;" #{E2AB8C}
            "supne;" #{E28A8B} "supplus;" #{E2AB80} "supset;" #{E28A83} "Supset;" #{E28B91} "supseteq;" #{E28A87}
            "supseteqq;" #{E2AB86} "supsetneq;" #{E28A8B} "supsetneqq;" #{E2AB8C} "supsim;" #{E2AB88} "supsub;" #{E2AB94}
            "supsup;" #{E2AB96} "swarhk;" #{E2A4A6} "swarr;" #{E28699} "swArr;" #{E28799} "swarrow;" #{E28699}
            "swnwar;" #{E2A4AA} "szlig;" #{C39F} "Tab;" #{09} "target;" #{E28C96} "Tau;" #{CEA4}
            "tau;" #{CF84} "tbrk;" #{E28EB4} "Tcaron;" #{C5A4} "tcaron;" #{C5A5} "Tcedil;" #{C5A2}
            "tcedil;" #{C5A3} "Tcy;" #{D0A2} "tcy;" #{D182} "tdot;" #{E2839B} "telrec;" #{E28C95}
            "Tfr;" #{F09D9497} "tfr;" #{F09D94B1} "there4;" #{E288B4} "therefore;" #{E288B4} "Therefore;" #{E288B4}
            "Theta;" #{CE98} "theta;" #{CEB8} "thetasym;" #{CF91} "thetav;" #{CF91} "thickapprox;" #{E28988}
            "thicksim;" #{E288BC} "ThickSpace;" #{E2819FE2808A} "ThinSpace;" #{E28089} "thinsp;" #{E28089} "thkap;" #{E28988}
            "thksim;" #{E288BC} "THORN;" #{C39E} "thorn;" #{C3BE} "tilde;" #{CB9C} "Tilde;" #{E288BC}
            "TildeEqual;" #{E28983} "TildeFullEqual;" #{E28985} "TildeTilde;" #{E28988} "timesbar;" #{E2A8B1} "timesb;" #{E28AA0}
            "times;" #{C397} "timesd;" #{E2A8B0} "tint;" #{E288AD} "toea;" #{E2A4A8} "topbot;" #{E28CB6}
            "topcir;" #{E2ABB1} "top;" #{E28AA4} "Topf;" #{F09D958B} "topf;" #{F09D95A5} "topfork;" #{E2AB9A}
            "tosa;" #{E2A4A9} "tprime;" #{E280B4} "trade;" #{E284A2} "TRADE;" #{E284A2} "triangle;" #{E296B5}
            "triangledown;" #{E296BF} "triangleleft;" #{E29783} "trianglelefteq;" #{E28AB4} "triangleq;" #{E2899C} "triangleright;" #{E296B9}
            "trianglerighteq;" #{E28AB5} "tridot;" #{E297AC} "trie;" #{E2899C} "triminus;" #{E2A8BA} "TripleDot;" #{E2839B}
            "triplus;" #{E2A8B9} "trisb;" #{E2A78D} "tritime;" #{E2A8BB} "trpezium;" #{E28FA2} "Tscr;" #{F09D92AF}
            "tscr;" #{F09D9389} "TScy;" #{D0A6} "tscy;" #{D186} "TSHcy;" #{D08B} "tshcy;" #{D19B}
            "Tstrok;" #{C5A6} "tstrok;" #{C5A7} "twixt;" #{E289AC} "twoheadleftarrow;" #{E2869E} "twoheadrightarrow;" #{E286A0}
            "Uacute;" #{C39A} "uacute;" #{C3BA} "uarr;" #{E28691} "Uarr;" #{E2869F} "uArr;" #{E28791}
            "Uarrocir;" #{E2A589} "Ubrcy;" #{D08E} "ubrcy;" #{D19E} "Ubreve;" #{C5AC} "ubreve;" #{C5AD}
            "Ucirc;" #{C39B} "ucirc;" #{C3BB} "Ucy;" #{D0A3} "ucy;" #{D183} "udarr;" #{E28785}
            "Udblac;" #{C5B0} "udblac;" #{C5B1} "udhar;" #{E2A5AE} "ufisht;" #{E2A5BE} "Ufr;" #{F09D9498}
            "ufr;" #{F09D94B2} "Ugrave;" #{C399} "ugrave;" #{C3B9} "uHar;" #{E2A5A3} "uharl;" #{E286BF}
            "uharr;" #{E286BE} "uhblk;" #{E29680} "ulcorn;" #{E28C9C} "ulcorner;" #{E28C9C} "ulcrop;" #{E28C8F}
            "ultri;" #{E297B8} "Umacr;" #{C5AA} "umacr;" #{C5AB} "uml;" #{C2A8} "UnderBar;" #{5F}
            "UnderBrace;" #{E28F9F} "UnderBracket;" #{E28EB5} "UnderParenthesis;" #{E28F9D} "Union;" #{E28B83} "UnionPlus;" #{E28A8E}
            "Uogon;" #{C5B2} "uogon;" #{C5B3} "Uopf;" #{F09D958C} "uopf;" #{F09D95A6} "UpArrowBar;" #{E2A492}
            "uparrow;" #{E28691} "UpArrow;" #{E28691} "Uparrow;" #{E28791} "UpArrowDownArrow;" #{E28785} "updownarrow;" #{E28695}
            "UpDownArrow;" #{E28695} "Updownarrow;" #{E28795} "UpEquilibrium;" #{E2A5AE} "upharpoonleft;" #{E286BF} "upharpoonright;" #{E286BE}
            "uplus;" #{E28A8E} "UpperLeftArrow;" #{E28696} "UpperRightArrow;" #{E28697} "upsi;" #{CF85} "Upsi;" #{CF92}
            "upsih;" #{CF92} "Upsilon;" #{CEA5} "upsilon;" #{CF85} "UpTeeArrow;" #{E286A5} "UpTee;" #{E28AA5}
            "upuparrows;" #{E28788} "urcorn;" #{E28C9D} "urcorner;" #{E28C9D} "urcrop;" #{E28C8E} "Uring;" #{C5AE}
            "uring;" #{C5AF} "urtri;" #{E297B9} "Uscr;" #{F09D92B0} "uscr;" #{F09D938A} "utdot;" #{E28BB0}
            "Utilde;" #{C5A8} "utilde;" #{C5A9} "utri;" #{E296B5} "utrif;" #{E296B4} "uuarr;" #{E28788}
            "Uuml;" #{C39C} "uuml;" #{C3BC} "uwangle;" #{E2A6A7} "vangrt;" #{E2A69C} "varepsilon;" #{CFB5}
            "varkappa;" #{CFB0} "varnothing;" #{E28885} "varphi;" #{CF95} "varpi;" #{CF96} "varpropto;" #{E2889D}
            "varr;" #{E28695} "vArr;" #{E28795} "varrho;" #{CFB1} "varsigma;" #{CF82} "varsubsetneq;" #{E28A8AEFB880}
            "varsubsetneqq;" #{E2AB8BEFB880} "varsupsetneq;" #{E28A8BEFB880} "varsupsetneqq;" #{E2AB8CEFB880} "vartheta;" #{CF91} "vartriangleleft;" #{E28AB2}
            "vartriangleright;" #{E28AB3} "vBar;" #{E2ABA8} "Vbar;" #{E2ABAB} "vBarv;" #{E2ABA9} "Vcy;" #{D092}
            "vcy;" #{D0B2} "vdash;" #{E28AA2} "vDash;" #{E28AA8} "Vdash;" #{E28AA9} "VDash;" #{E28AAB}
            "Vdashl;" #{E2ABA6} "veebar;" #{E28ABB} "vee;" #{E288A8} "Vee;" #{E28B81} "veeeq;" #{E2899A}
            "vellip;" #{E28BAE} "verbar;" #{7C} "Verbar;" #{E28096} "vert;" #{7C} "Vert;" #{E28096}
            "VerticalBar;" #{E288A3} "VerticalLine;" #{7C} "VerticalSeparator;" #{E29D98} "VerticalTilde;" #{E28980} "VeryThinSpace;" #{E2808A}
            "Vfr;" #{F09D9499} "vfr;" #{F09D94B3} "vltri;" #{E28AB2} "vnsub;" #{E28A82E28392} "vnsup;" #{E28A83E28392}
            "Vopf;" #{F09D958D} "vopf;" #{F09D95A7} "vprop;" #{E2889D} "vrtri;" #{E28AB3} "Vscr;" #{F09D92B1}
            "vscr;" #{F09D938B} "vsubnE;" #{E2AB8BEFB880} "vsubne;" #{E28A8AEFB880} "vsupnE;" #{E2AB8CEFB880} "vsupne;" #{E28A8BEFB880}
            "Vvdash;" #{E28AAA} "vzigzag;" #{E2A69A} "Wcirc;" #{C5B4} "wcirc;" #{C5B5} "wedbar;" #{E2A99F}
            "wedge;" #{E288A7} "Wedge;" #{E28B80} "wedgeq;" #{E28999} "weierp;" #{E28498} "Wfr;" #{F09D949A}
            "wfr;" #{F09D94B4} "Wopf;" #{F09D958E} "wopf;" #{F09D95A8} "wp;" #{E28498} "wr;" #{E28980}
            "wreath;" #{E28980} "Wscr;" #{F09D92B2} "wscr;" #{F09D938C} "xcap;" #{E28B82} "xcirc;" #{E297AF}
            "xcup;" #{E28B83} "xdtri;" #{E296BD} "Xfr;" #{F09D949B} "xfr;" #{F09D94B5} "xharr;" #{E29FB7}
            "xhArr;" #{E29FBA} "Xi;" #{CE9E} "xi;" #{CEBE} "xlarr;" #{E29FB5} "xlArr;" #{E29FB8}
            "xmap;" #{E29FBC} "xnis;" #{E28BBB} "xodot;" #{E2A880} "Xopf;" #{F09D958F} "xopf;" #{F09D95A9}
            "xoplus;" #{E2A881} "xotime;" #{E2A882} "xrarr;" #{E29FB6} "xrArr;" #{E29FB9} "Xscr;" #{F09D92B3}
            "xscr;" #{F09D938D} "xsqcup;" #{E2A886} "xuplus;" #{E2A884} "xutri;" #{E296B3} "xvee;" #{E28B81}
            "xwedge;" #{E28B80} "Yacute;" #{C39D} "yacute;" #{C3BD} "YAcy;" #{D0AF} "yacy;" #{D18F}
            "Ycirc;" #{C5B6} "ycirc;" #{C5B7} "Ycy;" #{D0AB} "ycy;" #{D18B} "yen;" #{C2A5}
            "Yfr;" #{F09D949C} "yfr;" #{F09D94B6} "YIcy;" #{D087} "yicy;" #{D197} "Yopf;" #{F09D9590}
            "yopf;" #{F09D95AA} "Yscr;" #{F09D92B4} "yscr;" #{F09D938E} "YUcy;" #{D0AE} "yucy;" #{D18E}
            "yuml;" #{C3BF} "Yuml;" #{C5B8} "Zacute;" #{C5B9} "zacute;" #{C5BA} "Zcaron;" #{C5BD}
            "zcaron;" #{C5BE} "Zcy;" #{D097} "zcy;" #{D0B7} "Zdot;" #{C5BB} "zdot;" #{C5BC}
            "zeetrf;" #{E284A8} "ZeroWidthSpace;" #{E2808B} "Zeta;" #{CE96} "zeta;" #{CEB6} "zfr;" #{F09D94B7}
            "Zfr;" #{E284A8} "ZHcy;" #{D096} "zhcy;" #{D0B6} "zigrarr;" #{E2879D} "zopf;" #{F09D95AB}
            "Zopf;" #{E284A4} "Zscr;" #{F09D92B5} "zscr;" #{F09D938F} "zwj;" #{E2808D} "zwnj;" #{E2808C}
        ]

        "partial" #[
            "Aacute" #{C381} "aacute" #{C3A1} "Acirc" #{C382} "acirc" #{C3A2} "acute" #{C2B4}
            "AElig" #{C386} "aelig" #{C3A6} "Agrave" #{C380} "agrave" #{C3A0} "amp" #{26}
            "AMP" #{26} "Aring" #{C385} "aring" #{C3A5} "Atilde" #{C383} "atilde" #{C3A3}
            "Auml" #{C384} "auml" #{C3A4} "brvbar" #{C2A6} "Ccedil" #{C387} "ccedil" #{C3A7}
            "cedil" #{C2B8} "cent" #{C2A2} "copy" #{C2A9} "COPY" #{C2A9} "curren" #{C2A4}
            "deg" #{C2B0} "divide" #{C3B7} "Eacute" #{C389} "eacute" #{C3A9} "Ecirc" #{C38A}
            "ecirc" #{C3AA} "Egrave" #{C388} "egrave" #{C3A8} "ETH" #{C390} "eth" #{C3B0}
            "Euml" #{C38B} "euml" #{C3AB} "frac12" #{C2BD} "frac14" #{C2BC} "frac34" #{C2BE}
            "gt" #{3E} "GT" #{3E} "Iacute" #{C38D} "iacute" #{C3AD} "Icirc" #{C38E}
            "icirc" #{C3AE} "iexcl" #{C2A1} "Igrave" #{C38C} "igrave" #{C3AC} "iquest" #{C2BF}
            "Iuml" #{C38F} "iuml" #{C3AF} "laquo" #{C2AB} "lt" #{3C} "LT" #{3C}
            "macr" #{C2AF} "micro" #{C2B5} "middot" #{C2B7} "nbsp" #{C2A0} "not" #{C2AC}
            "Ntilde" #{C391} "ntilde" #{C3B1} "Oacute" #{C393} "oacute" #{C3B3} "Ocirc" #{C394}
            "ocirc" #{C3B4} "Ograve" #{C392} "ograve" #{C3B2} "ordf" #{C2AA} "ordm" #{C2BA}
            "Oslash" #{C398} "oslash" #{C3B8} "Otilde" #{C395} "otilde" #{C3B5} "Ouml" #{C396}
            "ouml" #{C3B6} "para" #{C2B6} "plusmn" #{C2B1} "pound" #{C2A3} "quot" #{22}
            "QUOT" #{22} "raquo" #{C2BB} "reg" #{C2AE} "REG" #{C2AE} "sect" #{C2A7}
            "shy" #{C2AD} "sup1" #{C2B9} "sup2" #{C2B2} "sup3" #{C2B3} "szlig" #{C39F}
            "THORN" #{C39E} "thorn" #{C3BE} "times" #{C397} "Uacute" #{C39A} "uacute" #{C3BA}
            "Ucirc" #{C39B} "ucirc" #{C3BB} "Ugrave" #{C399} "ugrave" #{C3B9} "uml" #{C2A8}
            "Uuml" #{C39C} "uuml" #{C3BC} "Yacute" #{C39D} "yacute" #{C3BD} "yen" #{C2A5}
            "yuml" #{C3BF}
        ]
    ]

    comment {
        codepoints-spec: https://html.spec.whatwg.org/entities.json

        codepoints: collect [
            foreach key words-of codepoints: load-json read codepoints-spec [
                keep next form key
                keep to binary! select select/case codepoints key 'characters
            ]
        ]

        short-codepoints: collect [
            remove-each [code string] codepoints [
                if #";" <> last code [
                    keep code
                    keep string
                    true
                ]
            ]
        ]

        probe new-line/all/skip entities true 10
        probe new-line/all/skip short-codepoints true 10
    }

    codepoints: #[]
    ; character names and associated values

    foreach [code string] entities/("standard") [
        put/case codepoints code to string! string
    ]

    partials: #[]
    ; Entities that don't require trailing semi-colons

    foreach [code string] entities/("partial") [
        put/case partials code to string! string
    ]

    ; Characters from legacy Windows encodings
    ;
    replacements: #[
        128 8364
        130 8218
        131 402
        132 8222
        133 8230
        134 8224
        135 8225
        136 710
        137 8240
        138 352
        139 8249
        140 338
        142 381
        145 8216
        146 8217
        147 8220
        148 8221
        149 8226
        150 8211
        151 8212
        152 732
        153 8482
        154 353
        155 8250
        156 339
        158 382
        159 376
    ]

    permitted: complement charset collect [
        keep [
            0 - 8
            11
            13 - 31
            127 - 159
            55296 - 57343
            64976 - 65007
        ]

        ; higher range
        ;
        keep [
            65534 65535 
            131070 131071 196606 196607 262142 262143
            327678 327679 393214 393215 458750 458751
            524286 524287 589822 589823 655358 655359
            720894 720895 786430 786431 851966 851967
            917502 917503 983038 983039 1048574 1048575
            1114110 1114111
        ]
    ]

    element-prototype: make object! [
        name:
        space:
        void?:
        spelling:
        tag:
        end-tag: _
    ]

    elements: make map! collect-each [namespace elements] elements [
        keep namespace

        keep make object! collect-each element elements [
            keep to set-word! element: to string! element

            keep make element-prototype [
                name: lowercase copy element
                space: switch/default element [
                    "svg" [
                        "svg"
                    ]

                    "mathml" [
                        "mathml"
                    ]

                    "foreignObject" [
                        "html"
                    ]
                ][
                    namespace
                ]

                if name == spelling: element [
                    spelling: _
                ]

                tag: to tag! element

                void?: all [
                    find elements/("self-closing") tag
                    space = "html"
                ]

                if not void? [
                    end-tag: back insert copy tag "/"
                ]
            ]
        ]
    ]

    names: make map! collect-each namespace words-of elements [
        keep namespace

        keep make map! collect-each element words-of elements/:namespace [
            keep get in get element 'name
            keep element
        ]
    ]
]

html/references: context private [
    unknown: #"^(FFFD)"

    digit: charset "0123456789"
    hex-digit: charset "0123456789abcdefABCDEF"

    alpha-numeric: charset [
        #"0" - #"9"
        #"A" - #"Z"
        #"a" - #"z"
    ]

    permitted: html/reference/permitted
    replacements: html/reference/replacements

    name: make block! 155

    foreach key html/reference/codepoints [
        if not find/case name key/1 [
            repend name [
                '| key/1 make block! 100
            ]
        ]

        repend select/case name key/1 [
            '| next key to paren! reduce [
                quote decoder/value: select/case html/reference/codepoints key
            ]
        ]
    ]

    foreach [pipe initial branch] name [
        new-line remove new-line/all branch #(true) #(true)
    ]

    new-line remove new-line/all name #(true) #(true)

    partial: make block! 95

    foreach key sort/case/reverse keys-of html/reference/partials [
        if not find/case partial key/1 [
            repend partial [
                '| key/1 make block! 30
            ]
        ]

        repend select/case partial key/1 [
            '| next key to paren! reduce [
                quote decoder/value: select/case html/reference/partials key
            ]
        ]
    ]

    foreach [pipe initial branch] sort/case/skip/compare partial 3 2 [
        new-line remove new-line/all branch #(true) #(true)
    ]

    length-of new-line remove new-line/all partial #(true) #(true)

    decoder: context [
        state:
        token:
        continue?:
        attribute?:
        value:
        start:
        mark: _

        states: #[
            #character-reference [
                #"#"
                (state: #numeric-character-reference)
                |
                ahead alpha-numeric
                (state: #named-character-reference)
                |
                (state: #flush)
            ]

            #named-character-reference [
                name
                mark:
                (
                    assert [
                        #";" == mark/-1
                    ]

                    token/1: value
                    state: #done

                    continue?: no
                )
                |
                partial
                [
                    if (attribute?)
                    [#"=" | alpha-numeric]
                    (state: #flush)
                    |
                    (
                        append token/3 'missing-semicolon-after-character-reference
                        token/1: value

                        continue?: no
                    )
                ]
                |
                (state: #ambiguous-ampersand)
            ]

            #ambiguous-ampersand [
                copy value some alpha-numeric
                |
                #";"
                (
                    append token/3 'unknown-named-character-reference
                    state: #flush
                )
                |
                (state: #flush)
            ]

            #numeric-character-reference [
                [#"X" | #"x"]
                ahead hex-digit
                (state: #hexadecimal-character-reference)
                |
                ahead digit
                (state: #decimal-character-reference)
                |
                (
                    append token/3 'absence-of-digits-in-numeric-character-reference
                    state: #flush
                )
            ]

            #hexadecimal-character-reference [
                #";"
                (state: #numeric-character-reference-end)
                |
                copy value 1 6 hex-digit
                [
                    some hex-digit
                    (value: 9999999)
                    |
                    (value: to integer! to issue! value)
                ]
                |
                (
                    append token/3 'missing-semicolon-after-character-reference
                    state: #numeric-character-reference-end
                )
            ]

            #decimal-character-reference [
                #";"
                (state: #numeric-character-reference-end)
                |
                any #"0"
                copy value 1 7 digit
                [
                    some digit
                    (value: 9999999)
                    |
                    (value: to integer! value)
                ]
                |
                some #"0"
                (value: 0)
                |
                (
                    append token/3 'missing-semicolon-after-character-reference
                    state: #numeric-character-reference-end
                )
            ]

            #numeric-character-reference-end [
                (
                    token/1: case [
                        1114111 < value [
                            append token/3 'character-reference-outside-unicode-range
                            unknown
                        ]

                        find permitted value [
                            to char! value
                        ]

                        zero? value [
                            append token/3 'null-character-reference
                            #"^(FFFD)"
                        ]

                        57343 < value [
                            append token/3 'noncharacter-character-reference
                            to char! value
                        ]

                        55295 < value [
                            append token/3 'surrogate-character-reference
                            #"^(FFFD)"
                        ]

                        #else [
                            append token/3 'control-character-reference

                            any [
                                select replacements value
                                #"^(FFFD)"
                            ]
                        ]
                    ]

                    state: #done
                    continue?: no
                )
            ]

            #flush [
                mark:
                (
                    state: #done
                    token/1: copy/part start mark
                    continue?: no
                )
            ]

            #done [
                (do make error! "Should never get here...")
            ]
        ]

        loop: [
            while [
                if (continue?)
                states/(state)
            ]

            token/2:
        ]
    ]
][
    decode: func [
        encoding [string!]
        /attribute
    ][
        decoder/start: encoding
        decoder/state: #character-reference
        decoder/continue?: yes
        decoder/attribute?: did attribute

        decoder/token: reduce [
            #(none) encoding make block! 2
        ]

        ; https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
        ;
        parse/case next encoding decoder/loop

        decoder/token
    ]
]

decode-reference: :html/references/decode

html/lexers: context private [
    ascii: charset [
        0 - 127
    ]

    space: charset [
        9 10 13 32
    ]

    c0-control: charset [
        0 - 31
    ]

    alpha: charset [
        #"A" - #"Z"
        #"a" - #"z"
    ]

    alphanum: charset [
        #"0" - #"9"
        #"A" - #"Z"
        #"a" - #"z"
    ]

    text: complement charset "^@^-^/^M&< "
    rcdata-text: complement charset "^@&<"
    raw-text:
    script-text: complement charset "^@<"
    plain-text: complement charset "^@"
    escaped-script-text:
    comment-text: complement charset "^@-<"

    tag-name: complement charset [
        0 9 10 13 32 "/>"
    ]

    attribute-name: complement charset [
        0 9 10 13 32 {"'/<=>}
    ]

    attribute-quoted-double: complement charset [0 {"&}]
    attribute-quoted-single: complement charset [0 "&'"]
    attribute-unquoted: complement charset [
        0 9 10 13 32 {"&'<=>`}
    ]

    unknown: #"�"

    keywords: [
        doctype: [
            [#"d" | #"D"]
            [#"o" | #"O"]
            [#"c" | #"C"]
            [#"t" | #"T"]
            [#"y" | #"Y"]
            [#"p" | #"P"]
            [#"e" | #"E"]
        ]

        public: [
            [#"p" | #"P"]
            [#"u" | #"U"]
            [#"b" | #"B"]
            [#"l" | #"L"]
            [#"i" | #"I"]
            [#"c" | #"C"]
        ]

        system: [
            [#"s" | #"S"]
            [#"y" | #"Y"]
            [#"s" | #"S"]
            [#"t" | #"T"]
            [#"e" | #"E"]
            [#"m" | #"M"]
        ]
    ]

    tokens: make object! [
        space: [space _]
        text: [text _]
        tag: [tag _ _ _]
        end-tag: [end-tag _ _ _]
        doctype: [doctype _ _ _]
        comment: [comment _]
        end: [end]
    ]

    text-token: func [
        text [string!]
        /space
        /local token
    ][
        token: either space [tokens/space] [tokens/text]
        also token token/2: text
    ]

    tag-token: func [
        name [word! string!]
        /end
        /local token
    ][
        token: next select tokens either end ['end-tag] ['tag]

        token: also back token forall token [
            poke token 1 _
        ]

        if string? name [
            name: any [
                ; select html/reference/names/:namespace lowercase name
                name
            ]
        ]

        also token token/2: name
    ]

    state:
    token:
    continue?:

    buffer:
    mark:
    part:
    attribute: _
][
    ; 12.2.5 Tokenization https://html.spec.whatwg.org/multipage/parsing.html#tokenization

    lexer: _

    ; common patterns--they're expressive, but are they efficient?
    ;
    error: quote (
        report 'parse-error
    )

    null-character: [
        #"^@"
        (report 'unexpected-null-character)
    ]

    timely-end: [
        end
        (emit tokens/end)
    ]

    untimely-end: [
        end
        (
            report 'untimely-end
            use data
        )
    ]

    untimely-end-in-tag: [
        end
        mark:
        (
            report 'eof-in-tag
            use data
        )
    ]

    name-is-script: lib/use [
        from mark
    ][
        [
            from:
            some alpha
            ahead [space | #"/" | #">"]
            mark:
            if (same? mark find/match/tail from "script")
        ]
    ]

    name-is-closer: lib/use [
        from mark
    ][
        [
            from:
            some alpha
            ahead [space | #"/" | #">"]
            mark:
            if (same? mark find/match/tail from lexer/closer)
            (
                token: tag-token/end lexer/closer
                lexer/closer: _
            )
        ]
    ]

    flush: [
        mark:

        (
            tokens/text/2: copy/part buffer mark
            emit tokens/text
        )

        buffer:
    ]

    emit-unknown: [
        (
            tokens/text/2: unknown
            emit tokens/text
        )

        buffer:
    ]

    emit-reference: [
        mark:

        (
            part: decode-reference back mark

            tokens/text/2: part/1
            emit tokens/text

            foreach message part/3 [
                report :message
            ]

            buffer:
            mark: part/2
        )

        :mark
    ]

    emit-reference-in-attribute: [
        mark:

        (
            part: decode-reference/attribute back mark

            append attribute/2 part/1

            foreach message part/3 [
                report :message
            ]

            buffer:
            mark: part/2
        )

        :mark
    ]

    emit-tag: quote (
        emit token
        use data
    )

    ; Actions
    ;
    switch-to: func [
        target [word!]
    ][
        state: any [
            select states :target

            do make error! rejoin [
                "No Such State: " uppercase form target
            ]
        ]
    ]

    use: func [
        'target [word!]
        /until
        end-tag [string!]
    ][
        lexer/state: target

        if until [
            lexer/closer: :end-tag
        ]

        ; probe to tag! target
        ; probe copy/part series 10

        switch-to target
    ]

    rebase: func [
        lexer [object!]
        'state [word!]
        end-tag [string!]
    ][
        self/lexer: lexer

        use/until :state end-tag
    ]

    report: func [
        type [word!]
    ][
        repend lexer/errors [
            index? lexer/source type
        ]
    ]

    emit: func [
        token
    ][
        continue?: no
        also lexer/token: token token: _
    ]

    states: #[
        data: [
            buffer:
            copy part some space
            (emit text-token/space part)
            |
            some text
            any [
                some space
                some text
            ]
            flush
            |
            #"&"
            emit-reference
            |
            #"<"
            (use tag-open)
            |
            null-character
            emit-unknown
            |
            timely-end
        ]

        rcdata: [
            buffer:
            some rcdata-text
            flush
            |
            #"&"
            emit-reference
            |
            #"<"
            [
                #"/"
                name-is-closer
                (use data-end-tag)
                |
                flush
            ]
            |
            null-character
            emit-unknown
            |
            timely-end
        ]

        rawtext: [
            buffer:
            some raw-text
            flush
            |
            #"<"
            [
                #"/"
                name-is-closer
                (use data-end-tag)
                |
                flush
            ]
            |
            null-character
            emit-unknown
            |
            timely-end
        ]

        script-data: [
            buffer:
            some script-text
            flush
            |
            #"<"
            [
                #"/"
                name-is-closer
                (use data-end-tag)
                |
                #"-"
                some #"-"
                [
                    #">"
                    |
                    (use script-data-escaped)
                ]
                flush
                |
                flush
            ]
            |
            null-character
            emit-unknown
            |
            timely-end
        ]

        plaintext: [
            buffer:
            some plain-text
            flush
            |
            null-character
            emit-unknown
            |
            timely-end
        ]

        tag-open: [
            #"!"
            (use markup-declaration-open)
            |
            #"/"
            (use end-tag-open)
            |
            copy part [
                alpha
                any alphanum
            ]
            (
                use tag-name
                token: tag-token part
            )
            |
            ahead #"?"
            (
                use bogus-comment
                report 'expected-tag-name-but-got-question-mark
            )
            |
            end
            (
                use data
                report 'eof-before-tag-name
            )
            flush
            |
            (
                use data
                report 'expected-tag-name
            )
            flush
        ]

        end-tag-open: [
            copy part some alpha
            (
                use tag-name
                token: tag-token/end part
            )
            |
            #">"
            (
                use data
                report 'missing-end-tag-name
            )
            |
            end
            (
                use data
                report 'eof-before-tag-name
            )
            flush
            |
            (
                use bogus-comment
                report 'invalid-first-character-of-tag-name
            )
        ]

        tag-name: [
            copy part some tag-name
            (append token/2 lowercase part)
            |
            some space
            (use before-attribute-name)
            |
            #"/"
            (use self-closing-start-tag)
            |
            #">"
            emit-tag
            |
            null-character
            (append token/2 unknown)
            |
            untimely-end-in-tag
        ]

        data-end-tag: [
            space
            (use before-attribute-name)
            |
            #"/"
            (use self-closing-start-tag)
            |
            #">"
            (
                use data
                emit token
            )
            |
            untimely-end-in-tag
            |
            ??
            (write system/ports/input "error at data-end-tag^/" quit)
        ]

        script-data-escaped: [
            some escaped-script-text
            flush
            |
            #"-"
            opt [
                some #"-"
                #">"
                (use script-data)
            ]
            flush
            |
            #"<"
            [
                #"/"
                name-is-closer
                (use data-end-tag)
                |
                name-is-script
                (use script-data-double-escaped)
                flush
                |
                flush
            ]
            |
            null-character
            emit-unknown
            |
            untimely-end
            ; eof-in-script-html-comment-like-text
        ]

        script-data-double-escaped: [
            some escaped-script-double-test
            flush
            |
            #"<"
            opt [
                #"/"
                name-is-script
                (use script-data-escaped)
            ]
            flush
            |
            #"-"
            opt [
                some #"-"
                #">"
                (use script-data)
            ]
            flush
            |
            untimely-end
            ; eof-in-script-html-comment-like-text
        ]

        before-attribute-name: [
            some space
            |
            ahead [#"/" | #">" | end]
            (use after-attribute-name)
            |
            copy part opt [
                #"="
                (report 'unexpected-equals-sign-before-attribute-name)
            ]
            (
                use attribute-name

                ; we have one certain attribute, create attributes
                ;
                token/3: any [
                    token/3
                    make map! 2
                ]

                attribute: reduce [
                    part copy ""
                ]
            )
        ]

        attribute-name: [
            [
                copy part some attribute-name
                (lowercase part)
                |
                copy part [#"^"" | #"'" | #"<"]
                (report 'unexpected-character-in-attribute-name)
                |
                null-character
            ]
            (append attribute/1 part)
            |
            (
                either find token/3 attribute/1 [
                    report 'duplicate-attribute
                ][
                    put token/3 attribute/1 attribute/2
                ]
            )
            [
                #"="
                (use before-attribute-value)
                |
                (use after-attribute-name)
            ]
        ]

        after-attribute-name: [
            some space
            |
            #"/"
            (use self-closing-start-tag)
            |
            #"="
            (use before-attribute-value)
            |
            #">"
            emit-tag
            |
            untimely-end-in-tag
            |
            (
                use attribute-name

                attribute: reduce [
                    copy "" copy ""
                ]
            )
        ]

        before-attribute-value: [
            some space
            |
            #"^""
            (use attribute-value-double-quoted)
            |
            #"'"
            (use attribute-value-single-quoted)
            |
            #">"
            (report 'missing-attribute-value)
            emit-tag
            |
            (use attribute-value-unquoted)
        ]

        attribute-value-double-quoted: [
            copy part some attribute-quoted-double
            (append attribute/2 part)
            |
            #"&"
            emit-reference-in-attribute
            |
            #"^""
            (use after-attribute-value-quoted)
            |
            null-character
            (append attribute/2 unknown)
            |
            untimely-end-in-tag
        ]

        attribute-value-single-quoted: [
            copy part some attribute-quoted-single
            (append attribute/2 part)
            |
            #"&"
            emit-reference-in-attribute
            |
            #"'"
            (use after-attribute-value-quoted)
            |
            null-character
            (append attribute/2 unknown)
            |
            untimely-end-in-tag
        ]

        attribute-value-unquoted: [
            copy part some attribute-unquoted
            (append attribute/2 part)
            |
            #"&"
            emit-reference-in-attribute
            |
            [
                null-character
                |
                copy part [#"^"" | #"'" | #"<" | #"=" | #"`"]
                (report 'unexpected-character-in-unquoted-attribute-value)
            ]
            (append attribute/2 part)
            |
            some space
            (use before-attribute-name)
            |
            #">"
            emit-tag
            |
            untimely-end-in-tag
        ]

        after-attribute-value-quoted: [
            some space
            (use before-attribute-name)
            |
            #"/"
            (use self-closing-start-tag)
            |
            #">"
            emit-tag
            |
            untimely-end-in-tag
            |
            (
                report 'missing-whitespace-between-attributes
                use attribute-name
            )
        ]

        self-closing-start-tag: [
            #">"
            (token/4: 'self-closing)
            emit-tag
            |
            untimely-end-in-tag
            |
            (
                use before-attribute-name
                report 'unexpected-solidus-in-tag
            )
        ]

        markup-declaration-open: [
            "--"
            (
                use comment-start
                token: tokens/comment
                token/2: make string! 0
            )
            |
            keywords/doctype
            (use doctype)
            |
            ahead "[CDATA["
            (
                report 'CDATA-not-supported  ; ERRMSG
                use bogus-comment
            )
            |
            (
                report 'incorrectly-opened-comment
                use bogus-comment
            )
        ]

        bogus-comment: [
            (use data)
            [
                copy part to #">"
                skip
                |
                copy part to end
            ]
            (
                emit reduce [
                    'comment part
                ]
            )
        ]

        comment-start: [
            opt #"-"
            #">"
            (
                use data
                report 'abrupt-closing-of-empty-comment
                emit token
            )
            |
            (use comment)
        ]

        comment: [
            buffer:
            some comment-text
            mark:
            (append token/2 copy/part buffer mark)
            |
            #"-"
            [
                "->"
                (
                    emit token
                    use data
                )
                |
                "-!>"
                (
                    report 'incorrectly-closed-comment
                    emit token
                    use data
                )
                |
                (append token/2 #"-")
            ]
            |
            #"<"
            opt [
                (append token/2 #"<")

                "!--"
                [
                    #">"
                    (
                        use data
                        emit token
                    )
                    |
                    (report 'nested-comment)
                    "!>"
                    (
                        report 'incorrectly-closed-comment
                        emit token
                        use data
                    )
                    |
                    (append token/2 "incorrectly-opened-comment!--")
                ]
            ]
            |
            null-character
            emit-unknown
            |
            untimely-end
            (emit token)
        ]

        doctype: [
            some space
            (use before-doctype-name)
            |
            untimely-end
            (emit [doctype #(none) #(none) #(none) force-quirks])
            |
            (
                report 'missing-whitespace-before-doctype-name  ; ERRMSG
                use before-doctype-name
            )
        ]

        before-doctype-name: [
            some space
            |
            [
                null-character
                |
                copy part some alpha
                (lowercase part)
                |
                copy part skip
            ]
            (
                use doctype-name
                token: reduce ['doctype part _ _ _]
            )
            |
            #">"
            (
                use data
                emit [doctype #(none) #(none) #(none) force-quirks]
            )
            |
            untimely-end
            (emit [doctype #(none) #(none) #(none) force-quirks])
        ]

        doctype-name: [
            space
            (use after-doctype-name)
            |
            #">"
            (
                use data
                emit token
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            [
                null-character
                |
                copy part any alpha
                (lowercase part)
                |
                copy part skip
            ]
            (append token/2 part)
        ]

        after-doctype-name: [
            some space
            |
            #">"
            (
                use data
                emit token
            )
            |
            untimely-end (
                token/5: 'force-quirks
                emit token
            )
            |
            keywords/public
            (use after-doctype-public-keyword)
            |
            keywords/system (use after-doctype-system-keyword)
            |
            skip
            (
                use bogus-doctype
                token/5: 'force-quirks
            )
        ]

        after-doctype-public-keyword: [
            some space
            (use before-doctype-public-identifier)
            |
            #"^""
            error
            (
                use doctype-public-identifier-double-quoted
                token/3: make string! 0
            )
            |
            #"'"
            error
            (
                use doctype-public-identifier-single-quoted
                token/3: make string! 0
            )
            |
            #">" error
            (
                use data
                token/5: 'force-quirks
                emit token
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            skip
            error
            (
                use bogus-doctype
                token/5: 'force-quirks
            )
        ]

        before-doctype-public-identifier: [
            some space
            |
            #"^""
            (
                use doctype-public-identifier-double-quoted
                token/3: make string! 0
            )
            |
            #"'"
            (
                use doctype-public-identifier-single-quoted
                token/3: make string! 0
            )
            |
            #">" error
            (
                use data
                token/5: 'force-quirks
                emit token
            )
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            skip
            error
            (
                use bogus-doctype
                token/5: 'force-quirks
            )
        ]

        doctype-public-identifier-double-quoted: [
            #"^""
            (use after-doctype-public-identifier)
            |
            #">"
            error
            (
                use data
                token/5: 'force-quirks
                emit token
            )
            |
            untimely-end (
                token/5: 'force-quirks
                emit token
            )
            |
            [
                null-character
                |
                copy part [
                    some alpha | skip
                ]
            ]
            (append token/3 part)
        ]

        doctype-public-identifier-single-quoted: [
            #"'"
            (use after-doctype-public-identifier)
            |
            #">"
            error
            (
                use data
                token/5: 'force-quirks
                emit token
            )
            |
            untimely-end (
                token/5: 'force-quirks
                emit token
            )
            |
            [
                null-character
                |
                copy part [
                    some alpha | skip
                ]
            ]
            (append token/3 part)
        ]

        after-doctype-public-identifier: [
            space
            (use between-doctype-public-and-system-identifiers)
            |
            #">"
            (
                use data
                emit token
            )
            |
            #"^""
            error
            (
                use doctype-system-identifier-double-quoted
                token/4: make string! 0
            )
            |
            #"'"
            error
            (
                use doctype-system-identifier-single-quoted
                token/4: make string! 0
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            skip
            error
            (
                use bogus-doctype
                token/5: 'force-quirks
            )
        ]

        between-doctype-public-and-system-identifiers: [
            some space
            |
            #">"
            (
                use data
                emit token
            )
            |
            #"^""
            (
                use doctype-system-identifier-double-quoted
                token/4: make string! 0
            )
            |
            #"'"
            (
                use doctype-system-identifier-single-quoted
                token/4: make string! 0
            )
            |
            untimely-end
            (token/5: 'force-quirks)
            |
            skip
            error
            (
                use bogus-doctype
                token/5: 'force-quirks
            )
        ]

        after-doctype-system-keyword: [
            some space
            (use before-doctype-system-identifier)
            |
            #"^""
            (
                use doctype-system-identifier-double-quoted
                token/4: make string! 0
            )
            |
            #"'"
            (
                use doctype-system-identifier-single-quoted
                token/4: make string! 0
            )
            |
            #">"
            (
                use data
                report 'Premature-end-of-DOCTYPE-System-ID  ; ERRMSG
                token/5: 'force-quirks
                emit token
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            skip
            (
                use bogus-doctype
                report 'Unexpected-value-in-DOCTYPE-declaration  ; ERRMSG
                token/5: 'force-quirks
            )
        ]

        before-doctype-system-identifier: [
            some space
            |
            #"^""
            (
                use doctype-system-identifier-double-quoted
                token/4: make string! 0
            )
            |
            #"'"
            (
                use doctype-system-identifier-single-quoted
                token/4: make string! 0
            )
            |
            #">"
            error
            (
                use data
                report 'system-identifier-missing
                token/5: 'force-quirks
                emit token
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            skip
            error
            (
                use bogus-doctype
                token/5: 'force-quirks
            )
        ]

        doctype-system-identifier-double-quoted: [
            #"^""
            (use after-doctype-system-identifier)
            |
            #">"
            error
            (
                use data
                token/5: 'force-quirks
                emit token
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            [
                null-character
                |
                copy part some [
                    space | alpha
                ]
                (lowercase part)
                |
                copy part skip
            ]
            (append token/4 part)
        ]

        doctype-system-identifier-single-quoted: [
            #"'"
            (use after-doctype-system-identifier)
            |
            #">"
            error
            (
                use data
                token/5: 'force-quirks
                emit token
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            [
                null-character
                |
                copy part some [
                    space | alpha
                ]
                (lowercase part)
                |
                copy part skip
            ]
            (append token/4 part)
        ]

        after-doctype-system-identifier: [
            some space
            |
            #">"
            (
                use data
                emit token
            )
            |
            untimely-end
            (
                token/5: 'force-quirks
                emit token
            )
            |
            skip
            (use bogus-doctype)
        ]

        bogus-doctype: [
            #">"
            (
                use data
                emit token
            )
            |
            end
            (
                use data
                emit token
            )
            |
            skip
        ]
    ]

    prototype: make object! [
        source:
        token:
        state:
        closer:
        is-done:
        errors: _
    ]

    new: func [
        encoding [string!]
    ][
        make prototype [
            source: encoding
            state: 'data
            is-done: no
            errors: copy []
        ]
    ]

    next: func [
        lexer [object!]
    ][
        if not lexer/is-done [
            self/lexer: lexer

            continue?: yes
            token: _

            switch-to lexer/state

            parse/case lexer/source [
                while [
                    if (continue?)
                    state
                ]

                lexer/source:
            ]

            if [end] = lexer/token [
                lexer/is-done: yes
            ]

            lexer/token
        ]
    ]
]

html/decoders: context [
    lexers: html/lexers

    prototype: make object! [
        next:
        event:
        value:
        attributes:
        token:
        lexer:
        errors:
        state: _
    ]

    new: func [
        source [string!]
    ][
        make prototype [
            lexer: lexers/new source
            token: lexers/next lexer
            errors: lexer/errors
        ]
    ]

    next: func [
        decoder [object!]
        /local continue? token text
    ][
        token: decoder/token

        decoder/event:
        decoder/value:
        decoder/attributes: _

        continue?: yes

        while [
            continue?
        ][
            switch/default token/1 [
                text
                space [
                    either string? text [
                        append text token/2
                    ][
                        text: join "" token/2
                    ]
                ]

                tag [
                    decoder/event: 'open
                    decoder/value: token/2
                    decoder/attributes: token/3

                    if token/4 [
                        decoder/event: 'empty
                    ]

                    switch token/2 [
                        "title"
                        "textarea" [
                            lexers/rebase decoder/lexer rcdata token/2
                        ]

                        "script" [
                            lexers/rebase decoder/lexer script-data token/2
                        ]

                        "style"
                        "xmp"
                        "iframe"
                        "noembed"
                        "noframes" [
                            lexers/rebase decoder/lexer rawtext token/2
                        ]

                        "plaintext" [
                            lexers/rebase decoder/lexer plaintext token/2
                        ]
                    ]

                    continue?: no
                ]

                end-tag [
                    decoder/event: 'close
                    decoder/value: token/2

                    continue?: no
                ]

                comment [
                    decoder/event: 'comment
                    decoder/value:  token/2

                    continue?: no
                ]

                doctype [
                    decoder/event: 'doctype
                    decoder/value: token/2

                    continue?: no
                ]

                end [
                    continue?: no
                ]
            ][
                ? token
            ]

            ; check if we need to add accumulated text to the queue
            ;
            token:
            decoder/token: lexers/next decoder/lexer

            if all [
                text
                not find [text space] token/1
            ][
                decoder/event: 'text
                decoder/value: text

                continue?: no
            ]
        ]

        decoder/event
    ]

    to-block: func [
        source [string!]
        /local decoder
    ][
        decoder: new source

        neaten collect [
            while [
                next decoder
            ][
                switch/default decoder/event [
                    open [
                        keep to tag! decoder/value

                        if map? decoder/attributes [
                            keep decoder/attributes
                        ]
                    ]

                    empty [
                        keep to tag! decoder/value

                        if map? decoder/attributes [
                            keep decoder/attributes
                        ]

                        keep </>
                    ]

                    close [
                        keep to tag! join #"/" decoder/value
                    ]

                    text [
                        keep decoder/value
                    ]

                    doctype [
                        keep join <!DOCTYPE > decoder/value
                    ]

                    comment [
                        keep to tag! rejoin [
                            "!--" decoder/value "--"
                        ]
                    ]

                    end _
                ][
                    ? decoder
                ]
            ]

            if not empty? decoder/errors [
                ; probe neaten decoder/errors
            ]
        ]
    ]
]

html/unpackers: context private [
    reference: html/reference

    lexers: html/lexers

    tracer?: false

    ???: func [
        value /local val
    ][
        if tracer? [
            if map? val: value [
                val: intersect val #[type _ name _ value _]
            ]

            write console:// join mold/part val 50 newline
        ]

        value
    ]

    probe-stack: func [
        stack [block!]
    ][
        write console:// neaten collect-each item stack [
            either map? item [
                keep intersect item #[type _ name _ value _]
            ][
                keep make map! reduce ['type type-of/word item 'value item]
            ]
        ]
    ]

    mold-token: func [
        token [block!]
    ][
        either 'tag = token/1 [
            ; also mold token
            rejoin [
                "[tag "
                mold token/2
                #" "
                either map? token/3 [
                    join #"#" mold neaten/flat body-of token/3
                ][
                    #"_"
                ]
                #" "
                either none? token/4 [
                    #"_"
                ][
                    #"/"
                ]
                #"]"
            ]
        ][
            replace/all mold token newline "^^/"
        ]
    ]

    mold-element: func [
        element [map!]
    ][
        to tag! rejoin collect [
            keep element/name
            
            if element/value [
                foreach [name value] element/value [
                    keep #" "
                    keep name
                    keep #"="
                    keep mold value
                    ; for debugging, no need to sanitize
                ]
            ]

            if none? element/first [
                keep " /"
            ]
        ]
    ]

    mold-elements: func [
        list [block!]
    ][
        mold neaten/flat collect-each element list [
            either issue? element [
                keep mold element
            ][
                keep mold-element element
            ]
        ]
        
    ]

    mold-open-elements: func [] [
        mold-elements open-elements
    ]

    mold-active-formatting: func [] [
        mold-elements active-formatting-elements
    ]

    probe-stacks: does [
        print [
            "OPEN ELEMENTS:" mold-open-elements newline
            "ACTIVE FORMATTING:" mold-active-formatting
        ]
    ]

    specials: [
        "address" "applet" "area" "article" "aside" "base" "basefont" "bgsound" "blockquote" "body" "br" "button"
        "caption" "center" "col" "colgroup" "dd" "details" "dir" "div" "dl" "dt" "embed" "fieldset" "figcaption"
        "figure" "footer" "form" "frame" "frameset" "h1" "h2" "h3" "h4" "h5" "h6" "head" "header" "hgroup" "hr" "html"
        "iframe" "img" "input" "isindex" "li" "link" "listing" "main" "marquee" "meta" "nav" "noembed" "noframes"
        "noscript" "object" "ol" "p" "param" "plaintext" "pre" "script" "section" "select" "source" "style"
        "summary" "table" "tbody" "td" "template" "textarea" "tfoot" "th" "thead" "title" "tr" "track" "ul" "wbr" "xmp"
        "mi" "mo" "mn" "ms" "mtext" "annotation-xml"
        "foreignobject" "desc" "title"
    ]

    formatting: [
        "a" "b" "big" "code" "em" "font" "i" "nobr" "s" "small" "strike" "strong" "tt" "u"
    ]

    scopes: #[
        default: [
            "applet" "caption" "html" "table" "td" "th" "marquee" "object"  ; html
            "mi" "mo" "mn" "ms" "mtext" "annotation-xml"  ; mathml
            "foreignobject" "desc" "title"  ; svg
        ]

        list-item: [
            "applet" "caption" "html" "table" "td" "th" "marquee" "object"
            "mi" "mo" "mn" "ms" "mtext" "annotation-xml"
            "foreignobject" "desc" "title"
            "ul" "ol"
        ]

        button: [
            "applet" "caption" "html" "table" "td" "th" "marquee" "object"
            "mi" "mo" "mn" "ms" "mtext" "annotation-xml"
            "foreignobject" "desc" "title"
            "button"
        ]

        table: [
            "html" "table" "template"
        ]

        ; select: [
        ;     "optgroup" "option"
        ; ]
    ]

    implied-end-tags: [
        "dd" "dt" "li" "option" "optgroup" "p" "rb" "rp" "rt" "rtc"
    ]

    can-be-closed: [
        "dd" "dt" "li" "option" "optgroup" "p" "rb" "rp" "rt" "rtc"
        "tbody" "a" "td" "tfoot" "th" "thead" "tr" "body" "html"
    ]

    header-elements: [
        "h1" "h2" "h3" "h4" "h5" "h6"
    ]

    ruby-elements: [
        "rb" "rp" "rt" "rtc"
    ]

    tag-token: func [
        name [string!]
        /with
        attributes [map! none!]
        /end
    ][
        reduce [
            either end ['end-tag] ['tag]
            name
            any [:attributes _]
        ]
    ]

    push: func [
        node [map!]
    ][
        also current-node: node
        insert open-elements node
    ]

    pop-element: does [
        also
        take open-elements
        current-node: pick open-elements 1
    ]

    push-formatting: func [
        node [map! issue!]

        /local stack count
    ][
        also node
        either issue? node [
            ; issues are markers
            ;
            insert active-formatting-elements node
        ][
            count: 0
            stack: :active-formatting-elements

            while [
                not tail? stack
            ][
                case [
                    issue? stack/1 [
                        break
                    ]

                    all [
                        node/name = stack/1/name
                        node/value == stack/1/value
                    ][
                        either count = 2 [
                            remove stack
                        ][
                            count: count + 1
                            stack: skip stack 1
                        ]
                    ]

                    #else [
                        stack: skip stack 1
                    ]
                ]
            ]

            insert active-formatting-elements node
        ]
    ]

    pop-formatting: func [
        node [map! issue!]
    ][
        also node either issue? node [
            while [
                not tail? active-formatting-elements
            ][
                if issue? take active-formatting-elements [
                    break
                ]
            ]
        ][
            remove-each element active-formatting-elements [
                same? element node
            ]
        ]
    ]

    find-element: func [
        from [block!]
        element [map!]
    ][
        catch [
            also _ forall from [
                case [
                    issue? from/1 [
                        break
                    ]

                    same? element from/1 [
                        throw from
                    ]
                ]
            ]
        ]
    ]

    select-element: func [
        from [block!]
        name [string!]
    ][
        foreach element from [
            case [
                issue? element [
                    break/return _
                ]

                element/name = name [
                    break/return element
                ]
            ]
        ]
    ]

    set-insertion-point: func [
        override-target [none! map!]
        /local target last-table
    ][
        target: any [
            :override-target
            current-node
        ]

        insertion-type: 'append

        insertion-point: either all [
            fostering?
            find ["table" "tbody" "tfoot" "thead" "tr"] target/name
        ][
            case [
                none? last-table: select-element open-elements "table" [
                    last open-elements
                ]

                last-table/parent [
                    insertion-type: 'before
                    last-table
                ]

                #else [
                    first next find-element open-elements last-table
                ]
            ]
        ][
            target
        ]
    ]

    reset-insertion-mode: func [
        /local stack
    ][
        https://html.spec.whatwg.org/multipage/parsing.html#the-insertion-mode

        stack: open-elements

        forall stack [
            if switch/default stack/1/name [
                "td"
                "th" [
                    either tail? next stack [
                        use in-body
                    ][
                        use in-cell
                    ]
                ]

                "tr" [
                    use in-row
                ]

                "tbody"
                "tfoot"
                "thead" [
                    use in-table-body
                ]

                "caption" [
                    use in-caption
                ]

                "colgroup" [
                    use in-column-group
                ]

                "table" [
                    use in-table
                ]

                ; <template> [
                ;     ; template not supported at this time
                ;     use in-body
                ; ]

                "head" [
                    either tail? next stack [
                        use in-body
                    ][
                        use in-head
                    ]
                ]

                "body" [
                    use in-body
                ]

                "frameset" [
                    use in-frameset
                ]

                "html" [
                    either document/head [
                        use after-head
                    ][
                        use before-head
                    ]
                ]
            ][
                if tail? next stack [
                    use in-body
                ]
            ][
                break
            ]
        ]
    ]

    insert-element: func [
        token [block!]
        /to
        parent [map!]
        /namespace
        'space [word!]
        /local node
    ][
        set-insertion-point any [
            :parent _
        ]

        if not map? :parent [
            parent: :open-elements/1
        ]

        if not word? :space [
            space: 'html
        ]

        node: switch insertion-type [
            append [
                dom/append insertion-point
            ]

            before [
                dom/insert-before insertion-point
            ]
        ]

        node/type: 'element
        node/name: token/2
        node/value: pick token 3

        node
    ]

    insert-comment: func [
        token [block!]
        /to
        parent [map!]
        /local node
    ][
        set-insertion-point any [
            :parent _
        ]

        node: switch insertion-type [
            append [
                dom/append insertion-point
            ]

            before [
                dom/insert-before insertion-point
            ]
        ]

        node/type: 'comment
        node/value: token/2

        node
    ]

    insert-text: func [
        token [block!]
        /to
        parent [map!]

        /local target
    ][
        set-insertion-point any [
            :parent _
        ]

        target: switch insertion-type [
            append [
                insertion-point/last
            ]

            before [
                insertion-point/back
            ]
        ]

        if not all [
            target
            target/type = 'text
        ][
            target: switch insertion-type [
                append [
                    dom/append insertion-point
                ]

                before [
                    dom/insert-before insertion-point
                ]
            ]

            target/type: 'text
            target/value: make string! 0
        ]

        append target/value token/2
    ]

    close-element: func [
        token [block!]
    ][
        foreach node open-elements [
            case [
                token/2 = node/name [
                    generate-implied-end-tags/thru :token/2
                    break
                ]

                find specials node/name [
                    report 'unexpected-close-tag
                    break
                ]
            ]
        ]
    ]

    find-in-scope: func [
        target [string! block!]
        /scope
        scope-name [word!]
        /local stack node
    ][
        target: join [] target

        stack: open-elements

        scope: any [
            select scopes any [
                scope-name
                'default
            ]

            do make error! rejoin [
                "Scope not available: " to tag! scope-name
            ]
        ]

        forall stack [
            case [
                find target stack/1/name [
                    break/return stack/1
                ]

                find scope stack/1/name [
                    break/return _
                ]
            ]
        ]
    ]

    find-element-in-scope: func [
        element [map!]
        /scope
        'scope-name [word!]
        /local stack
    ][
        stack: open-elements

        scope: any [
            select scopes any [
                scope-name
                'default
            ]

            do make error! rejoin [
                "Scope not available: " to tag! scope-name
            ]
        ]

        forall stack [
            case [
                same? element stack/1 [
                    break/return stack
                ]

                find scope stack/1/name [
                    break/return _
                ]
            ]
        ]
    ]

    close-thru: func [
        names [block! string!]
        /quiet
    ][
        names: join [] names

        until [
            did find names select pop-element 'name
        ]

        current-node
    ]

    generate-implied-end-tags: func [
        /thru
        names [string! block!]
        /except
        exceptions [string! block!]
    ][
        names: join [] any [
            names []
        ]

        exceptions: join names any [
            exceptions []
        ]

        while compose/only [
            ; close all of the tags on the implied-end-tags collection except exceptions
            ;
            find (exclude implied-end-tags exceptions) current-node/name
        ][
            pop-element
        ]

        if thru [
            if not find names current-node/name [
                report 'missing-end-tags
                ; better error?
            ]

            close-thru :names
        ]

        current-node
    ]

    close-para-if-in-scope: func [] [
        if find-in-scope/scope "p" 'button [
            generate-implied-end-tags/thru "p"
        ]
    ]

    reconstruct-formatting-elements: func [
        /local stack entry
    ][
        if not any [
            empty? active-formatting-elements
            issue? first active-formatting-elements
        ][
            while [
                not tail? active-formatting-elements
            ][
                either any [
                    issue? first active-formatting-elements
                    find-element open-elements first active-formatting-elements
                ][
                    break
                ][
                    active-formatting-elements: next active-formatting-elements
                ]
            ]

            while [
                not head? active-formatting-elements
            ][
                active-formatting-elements: back active-formatting-elements

                change/only active-formatting-elements push insert-element tag-token/with
                :active-formatting-elements/1/name
                :active-formatting-elements/1/value
            ]
        ]
    ]

    adopt: func [
        "Recreate formatting stack in new container (Adoption Agency Algorithm)"
        token [block!]

        /local
        formatting-element element clone subject count
        common-ancestor bookmark node last-node position mark furthest-block
    ][
        subject: token/2

        either all [
            equal? open-elements/1/name subject
            not find-element active-formatting-elements open-elements/1
        ][
            pop-element
        ][
            loop 8 [
                formatting-element: select-element active-formatting-elements subject

                case [
                    not formatting-element [
                        close-element token
                        break
                    ]

                    not find-element open-elements formatting-element [
                        report 'adoption-agency-1.4
                        pop-formatting formatting-element
                        break
                    ]

                    not find-element-in-scope formatting-element [
                        report 'adoption-agency-4.4
                        break
                    ]

                    not same? open-elements/1 formatting-element [
                        report 'adoption-agency-1.3
                    ]
                ]

                mark: find-element copy open-elements formatting-element
                common-ancestor: first next mark

                if not furthest-block: catch [
                    also _ while [
                        not head? mark
                    ][
                        mark: back mark

                        if find specials mark/1/name [
                            throw mark/1
                        ]
                    ]
                ][
                    until [
                        same? formatting-element pop-element
                    ]

                    pop-formatting formatting-element

                    break
                ]

                bookmark: find-element active-formatting-elements formatting-element
                node: last-node: furthest-block
                count: 0

                forever [
                    count: count + 1

                    node: first mark: next mark

                    case/all [
                        same? formatting-element node [
                            break
                        ]

                        all [
                            count > 3
                            find-element active-formatting-elements node
                        ][
                            pop-formatting node
                        ]

                        not find-element active-formatting-elements node [
                            remove find-element open-elements node
                            continue
                        ]
                    ]

                    clone: dom/make-node
                    clone/type: 'element
                    clone/name: node/name
                    clone/value: node/value

                    change/only find-element open-elements node clone
                    change/only find-element active-formatting-elements node clone

                    node: :clone

                    if same? furthest-block last-node [
                        bookmark: find-element active-formatting-elements clone
                    ]

                    dom/append-existing node dom/remove last-node

                    last-node: :node
                ]

                if last-node/parent [
                    dom/remove last-node
                ]

                set-insertion-point common-ancestor
                dom/append-existing insertion-point last-node

                clone: dom/make-node
                clone/type: 'element
                clone/name: formatting-element/name
                clone/value: formatting-element/value

                while [
                    furthest-block/first
                ][
                    dom/append-existing clone
                    dom/remove furthest-block/first
                ]

                dom/append-existing furthest-block clone

                insert/only bookmark clone
                pop-formatting formatting-element

                remove find-element open-elements formatting-element
                insert/only find-element open-elements furthest-block clone

                current-node: first open-elements
            ]
        ]
    ]

    clear-stack-to-table: func [
        /body
        /row
        /local target
    ][
        target: case [
            body [
                ["tbody" "tfoot" "thead" "template" "html"]
            ]

            row [
                ["tr" "template" "html"]
            ]

            <else> [
                scopes/table
            ]
        ]

        while compose/only [
            not find (target) current-node/name
        ][
            pop-element
        ]
    ]

    has-open-elements: func [] [
        foreach element open-elements [
            if not find can-be-closed element/name [
                break/return element
            ]
        ]
    ]

    finish-up: does [
        while [
            not empty? open-elements
        ][
            pop-element
        ]
    ]

    modes: #[
        initial: [
            "13.2.6.4.1 The 'initial' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#the-initial-insertion-mode

            space []

            doctype [
                document/name: token/2
                document/public: token/3
                document/system: token/4
                use before-html
            ]

            tag
            end-tag
            text
            end [
                switch token/1 [
                    tag [
                        report 'expected-doctype-but-got-start-tag
                    ]

                    end-tag [
                        report 'expected-doctype-but-got-end-tag
                    ]

                    text [
                        report 'expected-doctype-but-got-chars
                    ]

                    end [
                        report 'expected-doctype-but-got-eof
                    ]
                ]

                use before-html
                do-token token
            ]

            comment [
                insert-comment/to token document
            ]
        ]

        before-html: [
            "13.2.6.4.2 The 'before html' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#the-before-html-insertion-mode

            space []

            doctype [
                report 'unexpected-doctype
            ]

            <html> [
                push insert-element/to token document
                use before-head
            ]

            text
            tag
            </head>
            </body>
            </html>
            </br>
            end
            else [
                push insert-element/to tag-token "html" document
                use before-head
                do-token token
            ]

            comment [
                insert-comment/to token document
            ]
        ]

        before-head: [
            "13.2.6.4.3 The 'before head' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#the-before-head-insertion-mode

            space []

            doctype [
                report 'unexpected-doctype
            ]

            <html> [
                do-token/in token in-body
            ]

            <head> [
                document/head: push insert-element token
                use in-head
            ]

            text
            tag
            </head>
            </body>
            </html>
            </br>
            end
            else [
                document/head: push insert-element tag-token "head"
                use in-head
                do-token token
            ]

            end-tag [
                report 'unexpected-end-tag
            ]

            comment [
                insert-comment token
            ]
        ]

        in-head: [
            "13.2.6.4.4 The 'in head' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inhead

            space [
                insert-text token
            ]

            doctype [
                report 'unexpected-doctype
            ]

            <html> [
                do-token/in token in-body
            ]

            <base>
            <basefont>
            <bgsound>
            <link>
            <meta> [
                insert-element token
            ]

            <title> [
                push insert-element token
                lexers/rebase decoder rcdata token/2
                use/return text
            ]

            <noframes>
            <style> [
                push insert-element token
                lexers/rebase decoder rawtext form token/2
                use/return text
            ]

            <noscript> [
                ; scripting flag is false
                push insert-element token
                use in-head-noscript
            ]

            <script> [
                push insert-element token
                lexers/rebase decoder script-data form token/2
                use/return text
            ]

            <head> [
                ; error
            ]

            </head> [
                pop-element
                use after-head
            ]

            text
            tag
            </body>
            </html>
            </br>
            end
            else [
                pop-element
                use after-head
                do-token token
            ]

            end-tag [
                ; error
            ]

            comment [
                insert-comment token
            ]
        ]

        in-head-noscript: [
            "13.2.6.4.5 The 'in head noscript' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inheadnoscript

            space [
                do-token/in token in-head
            ]

            doctype [
                report 'unexpected-doctype
                ; error
            ]

            <html> [
                do-token/in token in-body
            ]

            <basefont>
            <bgsound>
            <link>
            <meta>
            <noframes>
            <style> [
                do-token/in token in-head
            ]

            <head>
            <noscript> [
                report 'unexpected-tag-in-noscript
                ; error
            ]

            </noscript> [
                pop-element
                use in-head
            ]

            text
            tag
            </br>
            end
            else [
                report 'unexpected-content-in-noscript
                node: node/parent
                use in-head
                do-token token
            ]

            end-tag [
                report 'unexpected-tag-in-noscript
                ; error
            ]

            comment [
                do-token/in token in-head
            ]
        ]

        after-head: [
            "13.2.6.4.6 The 'after head' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#the-after-head-insertion-mode

            space [
                insert-text token
            ]

            doctype [
                report 'unexpected-doctype
                ; error
            ]

            <html> [
                do-token/in token in-body
            ]

            <body> [
                document/body: push insert-element token
                use in-body
            ]

            <frameset> [
                push insert-element token
                use in-frameset
            ]

            <base>
            <basefont>
            <bgsound>
            <link>
            <meta>
            <noframes>
            <script>
            <style>
            <template>
            <title> [
                ; error
                push document/head
                do-token/in token in-head
            ]

            <head> [
                ; error
            ]

            text
            tag
            </body>
            </html>
            </br>
            end
            else [
                document/body: push insert-element tag-token "body"
                use in-body
                do-token token
            ]

            end-tag [
                ; error
            ]

            comment [
                insert-comment token
            ]
        ]

        in-body: [
            "13.2.6.4.7 The 'in body' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inbody

            space
            text [
                reconstruct-formatting-elements
                insert-text token
            ]

            doctype [
                report 'unexpected-doctype
            ]

            <html> [
                report 'unexpected-html-opening-tag
                ; error
                ; check attributes
            ]

            <base>
            <basefont>
            <bgsound>
            <link>
            <meta>
            <noframes>
            <script>
            <style>
            <template>
            <title> [
                do-token/in token in-head
            ]

            <body> [
                report 'unexpected-duplicate-body-tag
                ; check attributes
            ]

            <frameset> [
                report 'unexpected-frameset-tag
                ; handle frameset
            ]

            end [
                if has-open-elements [
                    report 'expected-closing-tag-but-got-eof
                ]

                finish-up
            ]

            </body> [
                either find-in-scope "body" [
                    if has-open-elements [
                        report 'premature-body-end-tag
                    ]

                    use after-body
                ][
                    report 'unexpected-body-end-tag
                ]
            ]

            </html> [
                either find-in-scope "body" [
                    if has-open-elements [
                        report 'premature-html-end-tag
                    ]

                    use after-body
                    do-token token
                ][
                    report 'unexpected-html-end-tag
                ]
            ]

            <address>
            <article>
            <aside>
            <blockquote>
            <center>
            <details>
            <dialog>
            <dir>
            <div>
            <dl>
            <fieldset>
            <figcaption>
            <figure>
            <footer>
            <header>
            <hgroup>
            <main>
            <nav>
            <ol>
            <p>
            <search>
            <section>
            <summary>
            <ul> [
                close-para-if-in-scope
                push insert-element token
            ]

            <h1>
            <h2>
            <h3>
            <h4>
            <h5>
            <h6> [
                close-para-if-in-scope

                if find header-elements current-node/name [
                    report 'nested-header-element
                    pop-element
                ]

                push insert-element token
            ]

            <pre>
            <listing> [
                close-para-if-in-scope
                push insert-element token
            ]

            <form> [
                either document/form [
                    report 'nested-form
                ][
                    close-para-if-in-scope
                    document/form: push insert-element token
                ]
            ]

            <li> [
                foreach node open-elements compose/deep [
                    case [
                        node/name = "li" [
                            generate-implied-end-tags/thru "li"
                            break
                        ]

                        find (exclude specials ["address" "div" "p"]) node/name [
                            break
                        ]
                    ]
                ]

                close-para-if-in-scope
                push insert-element token
            ]

            <dd>
            <dt> [
                foreach node open-elements compose/deep [
                    case [
                        node/name = "dd" [
                            generate-implied-end-tags/thru "dd"
                            break
                        ]

                        node/name = "dt" [
                            generate-implied-end-tags/thru "dt"
                            break
                        ]

                        find (exclude specials ["address" "div" "p"]) node/name [
                            break
                        ]
                    ]
                ]

                close-para-if-in-scope
                push insert-element token
            ]

            <plaintext> [
                close-para-if-in-scope
                push insert-element token
                lexers/use plaintext
            ]

            <button> [
                if find-in-scope "button" [
                    ; error
                    close-thru "button"
                ]

                reconstruct-formatting-elements
                push insert-element token
            ]

            </address>
            </article>
            </aside>
            </blockquote>
            </button>
            </center>
            </details>
            </dialog>
            </dir>
            </div>
            </dl>
            </fieldset>
            </figcaption>
            </figure>
            </footer>
            </header>
            </hgroup>
            </listing>
            </main>
            </menu>
            </nav>
            </ol>
            </pre>
            </search>
            </section>
            </select>
            </summary>
            </ul> [
                either find-in-scope :token/2 [
                    close-thru :token/2
                ][
                    ; error
                ]
            ]

            </form> [
                case [
                    none? document/form [
                        report 'unexpected-form-end-tag
                    ]

                    not find-element-in-scope document/form [
                        report 'mismatched-form-end-tag
                    ]

                    elide generate-implied-end-tags

                    same? document/form current-node [
                        pop-element
                    ]

                    #else [
                        report 'unexpected-form-end-tag

                        remove-each node open-elements [
                            same? node document/form
                        ]
                    ]
                ]

                document/form: _
            ]

            </p> [
                if not find-in-scope/scope "p" 'button [
                    push insert-element tag-token "p"
                ]

                close-para-if-in-scope
            ]

            </li> [
                either find-in-scope/scope "li" 'list-item [
                    close-thru "li"
                ][
                    ; error
                ]
            ]

            </dd>
            </dt> [
                either find-in-scope :token/2 [
                    close-thru :token/2
                ][
                    ; error
                ]
            ]

            </h1>
            </h2>
            </h3>
            </h4>
            </h5>
            </h6> [
                either find-in-scope :header-elements [
                    generate-implied-end-tags

                    if token/2 <> current-node/name [
                        ; error
                    ]

                    close-thru :header-elements
                ][
                    ; error
                ]
            ]

            <a> [
                wrap [
                    if element: select-element active-formatting-elements "a" [
                        adopt token

                        if find-element open-elements element [
                            remove find-element open-elements element
                        ]

                        if find-element active-formatting-elements element [
                            pop-formatting element
                        ]
                    ]
                ]

                reconstruct-formatting-elements
                push-formatting push insert-element token
            ]

            <b>
            <big>
            <code>
            <em>
            <font>
            <i>
            <s>
            <small>
            <strike>
            <strong>
            <tt>
            <u> [
                reconstruct-formatting-elements
                push-formatting push insert-element token
            ]

            <nobr> [
                reconstruct-formatting-elements

                if find-in-scope "nobr" [
                    ; error
                    do-token tag-token/end "nbr"
                    reconstruct-formatting-elements
                ]

                push-formatting push insert-element token
            ]

            </a>
            </b>
            </big>
            </code>
            </em>
            </font>
            </i>
            </nobr>
            </s>
            </small>
            </strike>
            </strong>
            </tt>
            </u> [
                adopt token
            ]

            <applet>
            <marquee>
            <object> [
                reconstruct-formatting-elements
                push insert-element token
                push-formatting to issue! token/2
            ]

            </applet>
            </marquee>
            </object> [
                either find-in-scope :token/2 [
                    close-thru :token/2

                    if mark: find/tail active-formatting-elements issue! [
                        remove/part active-formatting-elements mark
                    ]
                ][
                    report 'end-tag-too-early
                    token/2
                ]
            ]

            <table> [
                ; if not document/quirks-mode [
                close-para-if-in-scope
                ; ]
                push insert-element token
                use in-table
            ]

            </br> [
                do-token tag-token "br"
            ]

            <area>
            <br>
            <embed>
            <img>
            <keygen>
            <wbr> [
                reconstruct-formatting-elements
                insert-element token
                ; acknowledge-self-closing-flag
            ]

            <input> [
                either find-in-scope "select" [
                    report 'unexpected-input-in-select
                    close-thru "select"
                ][
                    reconstruct-formatting-elements
                    insert-element token
                    ; acknowledge-self-closing-flag
                ]
            ]

            <param>
            <source>
            <track> [
                insert-element token
            ]

            <hr> [
                close-para-if-in-scope
                insert-element token
                ; acknowledge self-closing flag
            ]

            <image> [
                report 'unexpected-image-tag
                token/2: "img"
                do-token token
            ]

            <textarea> [
                push insert-element token
                lexers/use/until rcdata form token/2
                use/return text
            ]

            <xmp> [
                close-para-if-in-scope
                reconstruct-formatting-elements
                push insert-element token
                lexers/use/until rawtext form token/2
                use/return text
            ]

            <iframe> [
                push insert-element token
                lexers/use/until rawtext form token/2
                use/return text
            ]

            <noembed> [
                push insert-element token
                lexers/use/until rawtext form token/2
                use/return text
            ]

            <select> [
                either find-in-scope "select" [
                    report 'nested-select
                    close-thru "select"
                ][
                    reconstruct-formatting-elements
                    push insert-element token
                ]
            ]

            <option> [
                case [
                    find-in-scope "select" [
                        generate-implied-end-tags/except "optgroup"

                        if find-in-scope "option" [
                            report 'unexpected-option-outside-optgroup
                        ]
                    ]

                    current-node/name = "option" [
                        pop-element
                    ]
                ]

                reconstruct-formatting-elements
                push insert-element token
            ]

            <optgroup> [
                case [
                    find-in-scope "select" [
                        generate-implied-end-tags

                        if find-in-scope "option" [
                            report 'unexpected-option-outside-optgroup
                        ]
                    ]

                    current-node/name = "option" [
                        pop-element
                    ]
                ]

                reconstruct-formatting-elements
                push insert-element token
            ]

            </option> [
                ; not really sure what the spec intends here, so...
                do-token/generic token
            ]

            <rb>
            <rtc> [
                if find-in-scope "ruby" [
                    generate-implied-end-tags

                    if not current-node/name = "ruby" [
                        ; error
                    ]
                ]

                push insert-element token
            ]

            <rp>
            <rt> [
                if find-in-scope "ruby" [
                    generate-implied-end-tags/except "rtc"

                    if not find ["ruby" "rtc"] current-node/name [
                        ; error
                    ]
                ]

                push insert-element token
            ]

            <math> [
                reconstruct-formatting-elements
                ; adjust-math-ml-attributes
                ; adjust-foreign-attributes
                push insert-element/namespace token mathml

                if find token 'self-closing [
                    pop-element
                ]
            ]

            <svg> [
                reconstruct-formatting-elements
                ; adjust-math-ml-attributes
                ; adjust-foreign-attributes
                push insert-element/namespace token svg

                if find token 'self-closing [
                    pop-element
                ]
            ]

            <caption>
            <col>
            <colgroup>
            <frame>
            <head>
            <tbody>
            <td>
            <tfoot>
            <th>
            <thead>
            <tr> [
                report 'unexpected-tag
                ; error
            ]

            tag [
                reconstruct-formatting-elements
                push insert-element token

                ; maybe do this for all of them?
                ;
                if find token 'self-closing [
                    pop-element
                ]
            ]

            end-tag [
                foreach node open-elements [
                    case [
                        node/name = token/2 [
                            generate-implied-end-tags/except token/2

                            if node/name <> current-node/name [
                                report 'mismatched-close-tag
                            ]

                            close-thru :node/name
                            break
                        ]

                        find specials node/name [
                            report 'mismatched-end-tag
                            break
                        ]
                    ]
                ]
            ]

            comment [
                insert-comment token
            ]
        ]

        text: [
            "13.2.6.4.8 The 'text' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incdata

            space
            text [
                insert-text token
            ]

            end-tag [
                ; possible alt <script> handler here
                pop-element
                use :return-mode
                return-mode: _
            ]

            end [
                use :return-mode
                return-mode: _
            ]

            comment [
                insert-comment token
            ]
        ]

        in-table: [
            "13.2.6.4.9 The 'in table' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intable

            space
            text [
                either find ["table" "tbody" "tfoot" "thead" "tr"] current-node/name [
                    pending-table-characters: reduce [
                        'space copy ""
                    ]

                    use/return in-table-text
                    do-token token
                ][
                    do-else token
                ]
            ]

            doctype [
                report 'unexpected-doctype
            ]

            <caption> [
                clear-stack-to-table
                push-formatting #caption
                push insert-element token

                use in-caption
            ]

            <colgroup> [
                clear-stack-to-table
                push insert-element token

                use in-column-group
            ]

            <col> [
                clear-stack-to-table
                push insert-element tag-token "colgroup"

                use in-column-group

                do-token token
            ]

            <tbody>
            <tfoot>
            <thead> [
                clear-stack-to-table
                push insert-element token

                use in-table-body
            ]

            <td>
            <th>
            <tr> [
                clear-stack-to-table
                push insert-element tag-token "tbody"

                use in-table-body

                do-token token
            ]

            <table> [
                report 'unexpected-start-tag-implies-end-tag
                do-token tag-token/end "table"

                do-token token
            ]

            <style>
            <script>
            <template> [
                do-token/in token in-head
            ]

            <input> [
                ; should there be an 'equal? here?
                ;
                either equal? select any [token/3 []] "type" "hidden" [
                    ; error
                    insert-element token
                    ; acknowledge-self-closing-flag token
                ][
                    do-else token
                ]
            ]

            <form> [
                ; error
                if not any [
                    select-element open-elements template
                    document/form
                ][
                    document/form: insert-element token
                ]
            ]

            </table> [
                either find-in-scope/scope "table" 'table [
                    close-thru "table"
                    reset-insertion-mode
                ][
                    report 'no-table-in-scope
                ]
            ]

            </body>
            </caption>
            </col>
            </colgroup>
            </html>
            </tbody>
            </td>
            </tfoot>
            </th>
            </thead>
            </tr> [
                ; error
            ]

            </template> [
                do-token/in token in-head
            ]

            end [
                do-token/in token in-body
            ]

            tag
            end-tag
            else [
                report 'unsupported-content-in-table
                fostering?: on
                do-token/in token in-body
                fostering?: off
            ]

            comment [
                insert-comment token
            ]
        ]

        in-table-text: [
            "13.2.6.4.10 The 'in table text' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intabletext

            space [
                append pending-table-characters/2 token/2
            ]

            text [
                append pending-table-characters/2 token/2
                pending-table-characters/1: 'text
            ]

            doctype
            tag
            end-tag
            comment
            end [
                either 'text = pending-table-characters/1 [
                    do-else/in pending-table-characters in-table
                    pending-table-characters: _
                    use :return-mode
                    do-token token
                ][
                    insert-text pending-table-characters
                    use :return-mode
                    do-token token
                ]
            ]
        ]

        in-caption: [
            "13.2.6.4.11 The 'in caption' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incaption

            <caption>
            <col>
            <colgroup>
            <tbody>
            <td>
            <tfoot>
            <th>
            <thead>
            <tr>
            </table> [
                either find-in-scope/scope "caption" 'table [
                    generate-implied-end-tags/thru "caption"
                    pop-formatting #caption
                    use in-table
                    do-token token
                ][
                    ; error
                ]
            ]

            </caption> [
                either find-in-scope/scope "caption" 'table [
                    generate-implied-end-tags/thru "caption"
                    pop-formatting #caption
                    use in-table
                ][
                    ; error
                ]
            ]

            </body>
            </col>
            </colgroup>
            </html>
            </tbody>
            </td>
            </tfoot>
            </th>
            </thead>
            </tr> [
                ; error
            ]

            space
            text
            doctype
            tag
            end-tag
            comment
            end [
                do-token/in token in-body
            ]
        ]

        in-column-group: [
            "13.2.6.4.12 The 'in column group' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incolgroup

            space [
                insert-text token
            ]

            doctype [
                report 'unexpected-doctype
            ]

            <html>
            end [
                do-token/in token in-body
            ]

            <col> [
                insert-element token
                ; acknowledge-self-closing-tag
            ]

            </colgroup> [
                either current-node/name = "colgroup" [
                    pop-element
                    use in-table
                ][
                    report 'did-we-err?
                    ; error
                ]
            ]

            </col> [
                ; error
            ]

            <template>
            </template> [
                do-token/in token in-head
            ]

            text
            tag
            end-tag _

            comment [
                insert-comment token
            ]
        ]

        in-table-body: [
            "13.2.6.4.13 The 'in table body' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intbody

            <tr> [
                clear-stack-to-table/body
                push insert-element token
                use in-row
            ]

            <th>
            <td> [
                ; error
                clear-stack-to-table/body
                push insert-element tag-token "tr"
                use in-row
                do-token token
            ]

            </tbody>
            </tfoot>
            </thead> [
                either find-in-scope/scope :token/2 'table [
                    clear-stack-to-table/body
                    pop-element
                    use in-table
                ][
                    ; error
                ]
            ]

            <caption>
            <col>
            <colgroup>
            <tbody>
            <tfoot>
            <thead>
            </table> [
                either find-in-scope/scope ["tbody" "tfoot" "thead"] 'table [
                    clear-stack-to-table/body
                    pop-element
                    use in-table
                    do-token token
                ][
                    ; error
                ]
            ]

            </body>
            </caption>
            </col>
            </colgroup>
            </html>
            </td>
            </th>
            </tr> [
                ; error
            ]

            space
            text
            doctype
            tag
            end-tag
            comment
            end [
                do-token/in token in-table
            ]
        ]

        in-row: [
            "13.2.6.4.14 The 'in row' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intr

            <th>
            <td> [
                clear-stack-to-table/row
                push insert-element token
                use in-cell
                push-formatting #cell
            ]

            </tr> [
                either find-in-scope/scope "tr" 'table [
                    clear-stack-to-table/row
                    pop-element
                    use in-table-body
                ][
                    ; error
                ]
            ]

            <caption>
            <col>
            <colgroup>
            <tbody>
            <tfoot>
            <thead>
            <tr>
            </table> [
                either find-in-scope/scope "tr" 'table [
                    clear-stack-to-table/row
                    pop-element
                    use in-table-body
                    do-token token
                ][
                    ; error
                ]
            ]

            </tbody>
            </tfoot>
            </thead> [
                case [
                    not find-in-scope/scope ["tbody" "tfoot" "thead"] 'table [
                        ; error
                    ]

                    not find-in-scope/scope "tr" 'table _

                    <else> [
                        clear-stack-to-table/row
                        pop-element
                        use in-table-body
                        do-token token
                    ]
                ]
            ]

            </body>
            </caption>
            </col>
            </colgroup>
            </html>
            </td>
            </th> [
                ; error
            ]

            space
            text
            doctype
            tag
            end-tag
            comment
            end [
                do-token/in token in-table
            ]
        ]

        in-cell: [
            "13.2.6.4.15 The 'in cell' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intd

            </td>
            </th> [
                either find-in-scope/scope :token/2 'table [
                    generate-implied-end-tags/thru ["td" "th"]
                    pop-formatting #cell
                    use in-row
                ][
                    ; error
                ]
            ]

            <caption>
            <col>
            <colgroup>
            <tbody>
            <td>
            <tfoot>
            <th>
            <thead>
            <tr> [
                either find-in-scope/scope ["td" "th"] 'table [
                    generate-implied-end-tags/thru ["td" "th"]
                    pop-formatting #cell
                    use in-row
                    do-token token
                ][
                    ; error
                ]
            ]

            </body>
            </caption>
            </col>
            </colgroup>
            </html> [
                ; error
            ]

            </table>
            </tbody>
            </tfoot>
            </thead>
            </tr> [
                either find-in-scope/scope :token/2 'table [
                    generate-implied-end-tags/thru ["td" "th"]
                    pop-formatting #cell
                    use in-row
                    do-token token
                ][
                    ; error
                ]
            ]

            space
            text
            doctype
            tag
            end-tag
            comment
            end [
                do-token/in token in-body
            ]
        ]

        in-template: [
            "13.2.6.4.16 The 'in template' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intemplate

            ; not implemented
        ]

        after-body: [
            "13.2.6.4.17 The 'after body' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterbody

            space
            <html> [
                do-token/in token in-body
            ]

            doctype [
                report 'unexpected-doctype
            ]

            </html> [
                use after-after-body
            ]

            end [
                finish-up
            ]

            text
            tag
            end-tag [
                ; error
                use body
                do-token token
            ]

            comment [
                insert-comment/to token last open-elements
            ]
        ]

        in-frameset: [
            "13.2.6.4.18 The 'in frameset' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inframeset

            space [
                insert-text token
            ]

            doctype [
                report 'unexpected-doctype
            ]

            <html> [
                do-token/in token body
            ]

            <frameset> [
                push insert-element token
            ]

            </frameset> [
                either current-node/name = "html" [
                    ; error
                ][
                    pop-element

                    if current-node/name <> "frameset" [
                        use after-frameset
                    ]
                ]
            ]

            <frame> [
                insert-element token
                ; acknowledge-self-closing-flag
            ]

            <noframes> [
                do-token/in token in-head
            ]

            end [
                if not same? current-node last open-elements [
                    report 'eof-in-frameset
                ]

                finish-up
            ]

            text
            tag
            end-tag [
                ; error
            ]

            comment [
                insert-comment token
            ]
        ]

        after-frameset: [
            "13.2.6.4.19 The 'after frameset' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterframeset

            space [
                insert-text token
            ]

            doctype [
                report 'unexpected-doctype
            ]

            <html> [
                do-token/in token in-body
            ]

            </html> [
                use after-after-frameset
            ]

            <noframes> [
                do-token/in token in-head
            ]

            end [
                finish-up
            ]

            text
            tag
            end-tag [
                ; error
                use body
                do-token token
            ]

            comment [
                insert-comment token
            ]
        ]

        after-after-body: [
            "13.2.6.4.20 The 'after after body' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-body-insertion-mode

            space
            doctype
            <html> [
                do-token/in token in-body
            ]

            end [
                finish-up
            ]

            text
            tag
            end-tag [
                ; error
                use in-body
                do-token token
            ]

            comment [
                insert-comment/to token document
            ]
        ]

        after-after-frameset: [
            "13.2.6.4.21 The 'after after frameset' insertion mode"
            https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-frameset-insertion-mode

            space
            doctype
            <html> [
                do-token/in token in-body
            ]

            end [
                finish-up
            ]

            <noframes> [
                do-token/in token in-head
            ]

            text [
                report 'expected-eof-but-got-char
            ]

            tag [
                report 'expected-eof-but-got-start-tag
            ]

            end-tag [
                report 'expected-eof-but-got-end-tag
            ]

            comment [
                insert-comment/to token document
            ]
        ]

        foreign-content: [
            "13.2.6.5 The rules for parsing tokens in foreign content"
            https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inforeign
        ]
    ]

    lib/use [
        events action
    ][
        foreach [mode actions] modes [
            put modes mode copy #[]

            assert [
                parse actions [
                    opt [
                        string!
                        (put modes/:mode 'name actions/1)

                        opt [
                            url!
                            (put modes/:mode 'link actions/2)
                        ]
                    ]

                    any [
                        copy events some [
                            tag! | word! | none!
                        ]

                        set action block!
                        (
                            action: func [token] action

                            foreach event events [
                                put modes/:mode event :action
                            ]
                        )
                    ]
                ]
            ]
        ]
    ]

    switch-to: func [
        name [word!]
    ][
        any [
            select modes name

            do make error! rejoin [
                "No Such Insertion Mode: "
                uppercase form name
            ]
        ]
    ]

    report: func [
        type [word! string!]
        ; info
    ][
        also type
        repend decoder/errors [
            index? decoder/source type
        ]
    ]

    tagify: func [
        name [word! string!]
        /end
        /local source
    ][
        name: any [
            select reference/names/("html") name
            select reference/names/("svg") name
            select reference/names/("mathml") name
            name
        ]

        any [
            if word? name [
                get in get :name either end ['end-tag] ['tag]
            ]

            name
        ]
    ]

    use: func [
        'name [word!]

        /return
    ][
        if return [
            return-mode: :insertion-mode
        ]

        insertion-mode: name

        mode:
        active-mode: switch-to name

        name
    ]

    do-token: func [
        token [string! block!]

        /in
        'other [word!]

        /main
        /generic

        /local target
    ][
        ; print collect [
        ;     either main [
        ;         keep form 'do-token
        ;     ][
        ;         keep form 'do-token/force
        ;     ]
        ;
        ;     keep mold to issue! insertion-mode
        ;
        ;     either in [
        ;         keep rejoin [
        ;             #"(" mold to issue! other #")"
        ;         ]
        ;     ]
        ;
        ;     keep mold-token token
        ; ]

        if in [
            active-mode: switch-to other
        ]

        current-node: pick open-elements 1

        target: case [
            generic token/1

            switch token/1 [
                tag [
                    find active-mode target: tagify token/2
                ]

                end-tag [
                    find active-mode target: tagify/end token/2
                ]
            ] target

            #(true) token/1
        ]

        active-mode/:target token

        active-mode: mode

        _
    ]

    do-else: func [
        token [block! string!]
        /in
        'other [word!]
    ][
        ; print [
        ;     'do-else mold to issue! insertion-mode mold-token this
        ; ]

        if in [
            active-mode: switch-to other
        ]

        current-node: pick open-elements 1

        active-mode/else token

        active-mode: mode

        _
    ]

    decoder:
    document:

    insertion-point:
    insertion-type:

    open-elements:
    active-formatting-elements: _

    mode:
    return-mode:
    active-mode:
    insertion-mode:

    current-node: _

    fostering?: no
    pending-table-characters: _
][
    unpack: func [
        source [string!] /err pp df
    ][
        document:

        insertion-point: dom/new
        insertion-type: 'append

        open-elements: make block! 12
        active-formatting-elements: make block! 6

        mode:
        return-mode:
        active-mode:
        insertion-mode: _

        fostering?: no
        pending-table-characters: _

        use initial

        decoder: lexers/new source

        if error? err: try [
            while [
                lexers/next decoder
            ][
                do-token/main decoder/token
            ]

        ][
            print [
                mold to issue! insertion-mode
                mold-token decoder/token
            ]

            do :err
        ]

        if not empty? decoder/errors [
            document/warnings: decoder/errors
        ]

        document
    ]
]

load-markup: get in html/decoders 'to-block
load-html: get in html/unpackers 'unpack
