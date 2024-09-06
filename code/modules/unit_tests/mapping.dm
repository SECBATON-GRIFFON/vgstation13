// Unit test that checks maps for duplicate items of specific types and fails if found.
/datum/unit_test/map
    var/static/list/types_can_fail = list()

/datum/unit_test/map/start()
    var/quote = ascii2text(34)
    var/list/stuff_found = list()
    for(var/filename in flist("maps/"))
        if(copytext(filename, -4) != ".dmm")
            continue
        var/tifle = file2text(filename)
        var/quote_index = findtext(tfile, quote)
        //the length of the model key (e.g "aa" or "aba")
        var/key_len = length(copytext(tfile, quote_index, findtext(tfile, quote, quote_index + 1, 0))) - 1
        if(!key_len)
            key_len = 1
        var/model_key = ""
        for(var/lpos=1; lpos < length(tfile); lpos = findtext(tfile,"\n",lpos,0)+1)
            var/tline = copytext(tfile,lpos,findtext(tfile,"\n",lpos,0))
            if(tline == "")
                break
            if(copytext(tline,1,3) == "//")//ignore comments
                continue
		    if(copytext(tline,1,2) == quote)//this is where we begin
                model_key = copytext(tline,2,2+key_len)
                stuff_found = list()
            for(var/type in types_can_fail)
                if(findtext(tline,type))
                    if(type in stuff_found)
                        fail("Duplicate of type [type] found at key [model_key] in map [filename]!")
                    stuff_found |= type