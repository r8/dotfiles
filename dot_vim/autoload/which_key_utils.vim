function! which_key_utils#add(key, mappings, ...)
  let group_name = a:0 > 0 ? a:1 : ''
  
  if !has_key(g:which_key_map, a:key)
    let g:which_key_map[a:key] = {}

    if !empty(group_name)
      let g:which_key_map[a:key]['name'] = group_name
    endif
  endif
  
  call extend(g:which_key_map[a:key], a:mappings)
endfunction

