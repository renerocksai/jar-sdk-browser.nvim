if exists('g:loaded_jar_sdk_browser')
    finish
endif
let g:loaded_jar_sdk_browser = 1

command! -nargs=1 Sdks lua require('jar-sdk-browser').browse({arg=<f-args>})