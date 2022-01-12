if exists('g:loaded_jar_sdk_browser')
    finish
endif
let g:loaded_jar_sdk_browser = 1

command! -nargs=? Sdks lua require('jar-sdk-browser').browse({arg='<f-args>'})
command! -nargs=1 -complete=file Sdkadd lua require('jar-sdk-browser').add_jar(<f-args>)

