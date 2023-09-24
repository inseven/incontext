{%

    function ancestors(document)
        local ancestor = document
        local ancestors = {}
        while true do
            ancestor = ancestor.closestAncestor()
            if ancestor then
                table.insert(ancestors, ancestor)
            else
                return ancestors
            end
        end
    end

    local function reversedipairsiter(t, i)
        i = i - 1
        if i ~= 0 then
            return i, t[i]
        end
    end

    function reversedipairs(t)
        return reversedipairsiter, t, #t + 1
    end

    function concat(values, separator)
        write(table.concat(values, separator))
    end

    function contains(items, item)
        for _, testItem in ipairs(items) do
            if testItem == item then
                return true
            end
        end
        return false
    end

    function empty(items)
        if next(items) == nil then
           return true
        else
            return false
        end
    end

    function last(items, index)
        return items[index+1] == nil
    end

    function filter(items, predicate)
        local result = {}
        for _, item in ipairs(items) do
            if predicate(item) then
                table.insert(result, item)
            end
        end
        return result
    end

%}
