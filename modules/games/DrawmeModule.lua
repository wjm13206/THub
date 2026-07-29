--!native
--!optimize 2
local modules = {}
local cache = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
Services = setmetatable({}, { __index = function(self, name) local success, cache = pcall(function() return cloneref(game:GetService(name)) end); if success then rawset(self, name, cache); return cache else error("无效服务: "..tostring(name)) end end})

local function drequire(name)
    if cache[name] ~= nil then
        return cache[name]
    end
    local module_func = modules[name]
    if not module_func then
        error("module '" .. name .. "' not found in bundle", 2)
    end
    cache[name] = true
    local result = module_func()
    if result ~= nil then
        cache[name] = result
    end
    return cache[name]
end

-- ======================== 所有解码依赖模块 (来自原脚本，完整保留) ========================

modules["PNGLib\\Chunks\\bKGD.lua"] = function()
    local function bKGD(file, chunk)
        local data = chunk.Data
        local bitDepth = file.BitDepth
        local colorType = file.ColorType
        bitDepth = (2 ^ bitDepth) - 1
        if colorType == 3 then
            local index = data:ReadByte()
            file.BackgroundColor = file.Palette[index]
        elseif colorType == 0 or colorType == 4 then
            local gray = data:ReadUInt16() / bitDepth
            file.BackgroundColor = Color3.fromHSV(0, 0, gray)
        elseif colorType == 2 or colorType == 6 then
            local r = data:ReadUInt16() / bitDepth
            local g = data:ReadUInt16() / bitDepth
            local b = data:ReadUInt16() / bitDepth
            file.BackgroundColor = Color3.new(r, g, b)
        end
    end
    return bKGD
end

modules["PNGLib\\Chunks\\cHRM.lua"] = function()
    local colors = {"White", "Red", "Green", "Blue"}
    local function cHRM(file, chunk)
        local chrome = {}
        local data = chunk.Data
        for i = 1, 4 do
            local color = colors[i]
            chrome[color] = {
                [1] = data:ReadUInt32() / 10e4;
                [2] = data:ReadUInt32() / 10e4;
            }
        end
        file.Chromaticity = chrome
    end
    return cHRM
end

modules["PNGLib\\Chunks\\gAMA.lua"] = function()
    local function gAMA(file, chunk)
        local data = chunk.Data
        local value = data:ReadUInt32()
        file.Gamma = value / 10e4
    end
    return gAMA
end

modules["PNGLib\\Chunks\\IDAT.lua"] = function()
    local function IDAT(file, chunk)
        local crc = chunk.CRC
        local hash = file.Hash or 0
        local data = chunk.Data
        local buffer = data.Buffer
        file.Hash = bit32.bxor(hash, crc)
        file.ZlibStream = file.ZlibStream .. buffer
    end
    return IDAT
end

modules["PNGLib\\Chunks\\IEND.lua"] = function()
    local function IEND(file)
        file.Reading = nil
    end
    return IEND
end

modules["PNGLib\\Chunks\\IHDR.lua"] = function()
    local function IHDR(file, chunk)
        local data = chunk.Data
        file.Width = data:ReadInt32();
        file.Height = data:ReadInt32();
        file.BitDepth = data:ReadByte();
        file.ColorType = data:ReadByte();
        file.Methods = {
            Compression = data:ReadByte();
            Filtering   = data:ReadByte();
            Interlace   = data:ReadByte();
        }
    end
    return IHDR
end

modules["PNGLib\\Chunks\\PLTE.lua"] = function()
    local function PLTE(file, chunk)
        if not file.Palette then
            file.Palette = {}
        end
        local data = chunk.Data
        local palette = data:ReadAllBytes()
        if #palette % 3 ~= 0 then
            error("PNG - Invalid PLTE chunk.")
        end
        for i = 1, #palette, 3 do
            local r = palette[i]
            local g = palette[i + 1]
            local b = palette[i + 2]
            local color = Color3.fromRGB(r, g, b)
            local index = #file.Palette + 1
            file.Palette[index] = color
        end
    end
    return PLTE
end

modules["PNGLib\\Chunks\\sRGB.lua"] = function()
    local function sRGB(file, chunk)
        local data = chunk.Data
        file.RenderIntent = data:ReadByte()
    end
    return sRGB
end

modules["PNGLib\\Chunks\\tEXt.lua"] = function()
    local function tEXt(file, chunk)
        local data = chunk.Data
        local key, value = "", ""
        for byte in data:IterateBytes() do
            local char = string.char(byte)
            if char == '\0' then
                key = value
                value = ""
            else
                value = value .. char
            end
        end
        file.Metadata[key] = value
    end
    return tEXt
end

modules["PNGLib\\Chunks\\tIME.lua"] = function()
    local function tIME(file, chunk)
        local data = chunk.Data
        local timeStamp = {
            Year  = data:ReadUInt16();
            Month = data:ReadByte();
            Day   = data:ReadByte();
            Hour   = data:ReadByte();
            Minute = data:ReadByte();
            Second = data:ReadByte();
        }
        file.TimeStamp = timeStamp
    end
    return tIME
end

modules["PNGLib\\Chunks\\tRNS.lua"] = function()
    local function tRNS(file, chunk)
        local data = chunk.Data
        local bitDepth = file.BitDepth
        local colorType = file.ColorType
        bitDepth = (2 ^ bitDepth) - 1
        if colorType == 3 then
            local palette = file.Palette
            local alphaMap = {}
            for i = 1, #palette do
                local alpha = data:ReadByte()
                if not alpha then
                    alpha = 255
                end
                alphaMap[i] = alpha
            end
            file.AlphaData = alphaMap
        elseif colorType == 0 then
            local grayAlpha = data:ReadUInt16()
            file.Alpha = grayAlpha / bitDepth
        elseif colorType == 2 then
            local r = data:ReadUInt16() / bitDepth
            local g = data:ReadUInt16() / bitDepth
            local b = data:ReadUInt16() / bitDepth
            file.Alpha = Color3.new(r, g, b)
        else
            error("PNG - Invalid tRNS chunk")
        end
    end
    return tRNS
end

modules["PNGLib\\Modules\\BinaryReader.lua"] = function()
    local BinaryReader = {}
    BinaryReader.__index = BinaryReader
    function BinaryReader.new(buffer)
        local reader = {
            Position = 1;
            Buffer = buffer;
            Length = #buffer;
        }
        return setmetatable(reader, BinaryReader)
    end
    function BinaryReader:ReadByte()
        local buffer = self.Buffer
        local pos = self.Position
        if pos <= self.Length then
            local result = buffer:sub(pos, pos)
            self.Position = pos + 1
            return result:byte()
        end
    end
    function BinaryReader:ReadBytes(count, asArray)
        local values = {}
        for i = 1, count do
            values[i] = self:ReadByte()
        end
        if asArray then
            return values
        end
        return unpack(values)
    end
    function BinaryReader:ReadAllBytes()
        return self:ReadBytes(self.Length, true)
    end
    function BinaryReader:IterateBytes()
        return function ()
            return self:ReadByte()
        end
    end
    function BinaryReader:TwosComplementOf(value, numBits)
        if value >= (2 ^ (numBits - 1)) then
            value = value - (2 ^ numBits)
        end
        return value
    end
    function BinaryReader:ReadUInt16()
        local upper, lower = self:ReadBytes(2)
        return (upper * 256) + lower
    end
    function BinaryReader:ReadInt16()
        local unsigned = self:ReadUInt16()
        return self:TwosComplementOf(unsigned, 16)
    end
    function BinaryReader:ReadUInt32()
        local upper = self:ReadUInt16()
        local lower = self:ReadUInt16()
        return (upper * 65536) + lower
    end
    function BinaryReader:ReadInt32()
        local unsigned = self:ReadUInt32()
        return self:TwosComplementOf(unsigned, 32)
    end
    function BinaryReader:ReadString(length)
        if length == nil then
            length = self:ReadByte()
        end
        local pos = self.Position
        local nextPos = math.min(self.Length, pos + length)
        local result = self.Buffer:sub(pos, nextPos - 1)
        self.Position = nextPos
        return result
    end
    function BinaryReader:ForkReader(length)
        local chunk = self:ReadString(length)
        return BinaryReader.new(chunk)
    end
    return BinaryReader
end

modules["PNGLib\\Modules\\Deflate.lua"] = function()
    local Deflate = {}
    local band = bit32.band
    local lshift = bit32.lshift
    local rshift = bit32.rshift
    local BTYPE_NO_COMPRESSION = 0
    local BTYPE_FIXED_HUFFMAN = 1
    local BTYPE_DYNAMIC_HUFFMAN = 2
    local lens = {
        [0] = 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
        35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
    }
    local lext = {
        [0] = 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
        3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
    }
    local dists = {
        [0] = 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
        257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
        8193, 12289, 16385, 24577
    }
    local dext = {
        [0] = 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
        7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
        12, 12, 13, 13
    }
    local order = {
        16, 17, 18, 0, 8, 7, 9, 6, 10, 5,
        11, 4, 12, 3, 13, 2, 14, 1, 15
    }
    local fixedLit = {0, 8, 144, 9, 256, 7, 280, 8, 288}
    local fixedDist = {0, 5, 32}
    local function createState(bitStream)
        local state = {
            Output = bitStream;
            Window = {};
            Pos = 1;
        }
        return state
    end
    local function write(state, byte)
        local pos = state.Pos
        state.Output(byte)
        state.Window[pos] = byte
        state.Pos = pos % 32768 + 1
    end
    local function memoize(fn)
        local meta = {}
        local memoizer = setmetatable({}, meta)
        function meta:__index(k)
            local v = fn(k)
            memoizer[k] = v
            return v
        end
        return memoizer
    end
    local pow2 = memoize(function (n)
        return 2 ^ n
    end)
    local isBitStream = setmetatable({}, { __mode = 'k' })
    local function createBitStream(reader)
        local buffer = 0
        local bitsLeft = 0
        local stream = {}
        isBitStream[stream] = true
        function stream:GetBitsLeft()
            return bitsLeft
        end
        function stream:Read(count)
            count = count or 1
            while bitsLeft < count do
                local byte = reader:ReadByte()
                if not byte then
                    return
                end
                buffer = buffer + lshift(byte, bitsLeft)
                bitsLeft = bitsLeft + 8
            end
            local bits
            if count == 0 then
                bits = 0
            elseif count == 32 then
                bits = buffer
                buffer = 0
            else
                bits = band(buffer, rshift(2^32 - 1, 32 - count))
                buffer = rshift(buffer, count)
            end
            bitsLeft = bitsLeft - count
            return bits
        end
        return stream
    end
    local function getBitStream(obj)
        if isBitStream[obj] then
            return obj
        end
        return createBitStream(obj)
    end
    local function sortHuffman(a, b)
        return a.NumBits == b.NumBits and a.Value < b.Value or a.NumBits < b.NumBits
    end
    local function msb(bits, numBits)
        local res = 0
        for i = 1, numBits do
            res = lshift(res, 1) + band(bits, 1)
            bits = rshift(bits, 1)
        end
        return res
    end
    local function createHuffmanTable(init, isFull)
        local hTable = {}
        if isFull then
            for val, numBits in pairs(init) do
                if numBits ~= 0 then
                    hTable[#hTable + 1] = {
                        Value = val;
                        NumBits = numBits;
                    }
                end
            end
        else
            for i = 1, #init - 2, 2 do
                local firstVal = init[i]
                local numBits = init[i + 1]
                local nextVal = init[i + 2]
                if numBits ~= 0 then
                    for val = firstVal, nextVal - 1 do
                        hTable[#hTable + 1] = {
                            Value = val;
                            NumBits = numBits;
                        }
                    end
                end
            end
        end
        table.sort(hTable, sortHuffman)
        local code = 1
        local numBits = 0
        for i, slide in ipairs(hTable) do
            if slide.NumBits ~= numBits then
                code = code * pow2[slide.NumBits - numBits]
                numBits = slide.NumBits
            end
            slide.Code = code
            code = code + 1
        end
        local minBits = math.huge
        local look = {}
        for i, slide in ipairs(hTable) do
            minBits = math.min(minBits, slide.NumBits)
            look[slide.Code] = slide.Value
        end
        local firstCode = memoize(function (bits)
            return pow2[minBits] + msb(bits, minBits)
        end)
        function hTable:Read(bitStream)
            local code = 1
            local numBits = 0
            while true do
                if numBits == 0 then
                    local index = bitStream:Read(minBits)
                    numBits = numBits + minBits
                    code = firstCode[index]
                else
                    local bit = bitStream:Read()
                    numBits = numBits + 1
                    code = code * 2 + bit
                end
                local val = look[code]
                if val then
                    return val
                end
            end
        end
        return hTable
    end
    local function parseZlibHeader(bitStream)
        local cm = bitStream:Read(4)
        local cinfo = bitStream:Read(4)
        local fcheck = bitStream:Read(5)
        local fdict = bitStream:Read(1)
        local flevel = bitStream:Read(2)
        local cmf = cinfo * 16  + cm
        local flg = fcheck + fdict * 32 + flevel * 64
        if cm ~= 8 then
            error("unrecognized zlib compression method: " .. cm)
        end
        if cinfo > 7 then
            error("invalid zlib window size: cinfo=" .. cinfo)
        end
        local windowSize = 2 ^ (cinfo + 8)
        if (cmf * 256 + flg) % 31 ~= 0 then
            error("invalid zlib header (bad fcheck sum)")
        end
        if fdict == 1 then
            error("FIX:TODO - FDICT not currently implemented")
        end
        return windowSize
    end
    local function parseHuffmanTables(bitStream)
        local numLits  = bitStream:Read(5)
        local numDists = bitStream:Read(5)
        local numCodes = bitStream:Read(4)
        local codeLens = {}
        for i = 1, numCodes + 4 do
            local index = order[i]
            codeLens[index] = bitStream:Read(3)
        end
        codeLens = createHuffmanTable(codeLens, true)
        local function decode(numCodes)
            local init = {}
            local numBits
            local val = 0
            while val < numCodes do
                local codeLen = codeLens:Read(bitStream)
                local numRepeats
                if codeLen <= 15 then
                    numRepeats = 1
                    numBits = codeLen
                elseif codeLen == 16 then
                    numRepeats = 3 + bitStream:Read(2)
                elseif codeLen == 17 then
                    numRepeats = 3 + bitStream:Read(3)
                    numBits = 0
                elseif codeLen == 18 then
                    numRepeats = 11 + bitStream:Read(7)
                    numBits = 0
                end
                for i = 1, numRepeats do
                    init[val] = numBits
                    val = val + 1
                end
            end
            return createHuffmanTable(init, true)
        end
        local numLitCodes = numLits + 257
        local numDistCodes = numDists + 1
        local litTable = decode(numLitCodes)
        local distTable = decode(numDistCodes)
        return litTable, distTable
    end
    local function parseCompressedItem(bitStream, state, litTable, distTable)
        local val = litTable:Read(bitStream)
        if val < 256 then
            write(state, val)
        elseif val == 256 then
            return true
        else
            local lenBase = lens[val - 257]
            local numExtraBits = lext[val - 257]
            local extraBits = bitStream:Read(numExtraBits)
            local len = lenBase + extraBits
            local distVal = distTable:Read(bitStream)
            local distBase = dists[distVal]
            local distNumExtraBits = dext[distVal]
            local distExtraBits = bitStream:Read(distNumExtraBits)
            local dist = distBase + distExtraBits
            for i = 1, len do
                local pos = (state.Pos - 1 - dist) % 32768 + 1
                local byte = assert(state.Window[pos], "invalid distance")
                write(state, byte)
            end
        end
        return false
    end
    local function parseBlock(bitStream, state)
        local bFinal = bitStream:Read(1)
        local bType = bitStream:Read(2)
        if bType == BTYPE_NO_COMPRESSION then
            local left = bitStream:GetBitsLeft()
            bitStream:Read(left)
            local len = bitStream:Read(16)
            local nlen = bitStream:Read(16)
            for i = 1, len do
                local byte = bitStream:Read(8)
                write(state, byte)
            end
        elseif bType == BTYPE_FIXED_HUFFMAN or bType == BTYPE_DYNAMIC_HUFFMAN then
            local litTable, distTable
            if bType == BTYPE_DYNAMIC_HUFFMAN then
                litTable, distTable = parseHuffmanTables(bitStream)
            else
                litTable = createHuffmanTable(fixedLit)
                distTable = createHuffmanTable(fixedDist)
            end
            repeat until parseCompressedItem(bitStream, state, litTable, distTable)
        else
            error("unrecognized compression type")
        end
        return bFinal ~= 0
    end
    function Deflate:Inflate(io)
        local state = createState(io.Output)
        local bitStream = getBitStream(io.Input)
        repeat until parseBlock(bitStream, state)
    end
    function Deflate:InflateZlib(io)
        local bitStream = getBitStream(io.Input)
        local windowSize = parseZlibHeader(bitStream)
        self:Inflate{
            Input = bitStream;
            Output = io.Output;
        }
        local bitsLeft = bitStream:GetBitsLeft()
        bitStream:Read(bitsLeft)
    end
    return Deflate
end

modules["PNGLib\\Modules\\Unfilter.lua"] = function()
    local Unfilter = {}
    function Unfilter:None(scanline, pixels, bpp, row)
        for i = 1, #scanline do
            pixels[row][i] = scanline[i]
        end
    end
    function Unfilter:Sub(scanline, pixels, bpp, row)
        for i = 1, bpp do
            pixels[row][i] = scanline[i]
        end
        for i = bpp + 1, #scanline do
            local x = scanline[i]
            local a = pixels[row][i - bpp]
            pixels[row][i] = bit32.band(x + a, 0xFF)
        end
    end
    function Unfilter:Up(scanline, pixels, bpp, row)
        if row > 1 then
            local upperRow = pixels[row - 1]
            for i = 1, #scanline do
                local x = scanline[i]
                local b = upperRow[i]
                pixels[row][i] = bit32.band(x + b, 0xFF)
            end
        else
            self:None(scanline, pixels, bpp, row)
        end
    end
    function Unfilter:Average(scanline, pixels, bpp, row)
        if row > 1 then
            for i = 1, bpp do
                local x = scanline[i]
                local b = pixels[row - 1][i]
                b = bit32.rshift(b, 1)
                pixels[row][i] = bit32.band(x + b, 0xFF)
            end
            for i = bpp + 1, #scanline do
                local x = scanline[i]
                local b = pixels[row - 1][i]
                local a = pixels[row][i - bpp]
                local ab = bit32.rshift(a + b, 1)
                pixels[row][i] = bit32.band(x + ab, 0xFF)
            end
        else
            for i = 1, bpp do
                pixels[row][i] = scanline[i]
            end
            for i = bpp + 1, #scanline do
                local x = scanline[i]
                local b = pixels[row - 1][i]
                b = bit32.rshift(b, 1)
                pixels[row][i] = bit32.band(x + b, 0xFF)
            end
        end
    end
    function Unfilter:Paeth(scanline, pixels, bpp, row)
        if row > 1 then
            local pr
            for i = 1, bpp do
                local x = scanline[i]
                local b = pixels[row - 1][i]
                pixels[row][i] = bit32.band(x + b, 0xFF)
            end
            for i = bpp + 1, #scanline do
                local a = pixels[row][i - bpp]
                local b = pixels[row - 1][i]
                local c = pixels[row - 1][i - bpp]
                local x = scanline[i]
                local p = a + b - c
                local pa = math.abs(p - a)
                local pb = math.abs(p - b)
                local pc = math.abs(p - c)
                if pa <= pb and pa <= pc then
                    pr = a
                elseif pb <= pc then
                    pr = b
                else
                    pr = c
                end
                pixels[row][i] = bit32.band(x + pr, 0xFF)
            end
        else
            self:Sub(scanline, pixels, bpp, row)
        end
    end
    return Unfilter
end

modules["modules.standard.png"] = function()
    local sub, format, split, loadstring, spawn = string.sub, string.format, string.split, loadstring, task.spawn
    local PNG = {}
    PNG.__index = PNG
    local chunks = {};
    local modules = {};
    local chunk_modules = { "PNGLib\\Chunks\\bKGD.lua", "PNGLib\\Chunks\\cHRM.lua", "PNGLib\\Chunks\\gAMA.lua", "PNGLib\\Chunks\\IDAT.lua", "PNGLib\\Chunks\\IEND.lua", "PNGLib\\Chunks\\IHDR.lua", "PNGLib\\Chunks\\PLTE.lua", "PNGLib\\Chunks\\sRGB.lua", "PNGLib\\Chunks\\tEXt.lua", "PNGLib\\Chunks\\tIME.lua", "PNGLib\\Chunks\\tRNS.lua" }
    local module_modules = { "PNGLib\\Modules\\BinaryReader.lua", "PNGLib\\Modules\\Deflate.lua", "PNGLib\\Modules\\Unfilter.lua" }
    function fetch(module_list)
        local r = {}
        for i,module_name in ipairs(module_list) do
            local ChunkName = sub(split(module_name, "\\")[3], 1, #split(module_name, "\\")[3] - 4)
            r[ChunkName] = drequire(module_name)
        end
        return r;
    end
    for n, v in next, fetch(chunk_modules) do
        chunks[n] = v
    end
    for n, v in next, fetch(module_modules) do
        modules[n] = v
    end
    local Deflate = modules.Deflate
    local Unfilter = modules.Unfilter
    local BinaryReader = modules.BinaryReader
    local function getBytesPerPixel(colorType)
        if colorType == 0 or colorType == 3 then
            return 1
        elseif colorType == 4 then
            return 2
        elseif colorType == 2 then
            return 3
        elseif colorType == 6 then
            return 4
        else
            return 0
        end
    end
    local function clampInt(value, min, max)
        local num = tonumber(value) or 0
        num = math.floor(num + .5)
        return math.clamp(num, min, max)
    end
    local function indexBitmap(file, x, y)
        local width = file.Width
        local height = file.Height
        x = clampInt(x, 1, width)
        y = clampInt(y, 1, height)
        local bitmap = file.Bitmap
        local bpp = file.BytesPerPixel
        local i0 = ((x - 1) * bpp) + 1
        local i1 = i0 + bpp
        return bitmap[y], i0, i1
    end
    function PNG:GetPixel(x, y)
        local row, i0, i1 = indexBitmap(self, x, y)
        local colorType = self.ColorType
        local color, alpha do
            if colorType == 0 then
                local gray = unpack(row, i0, i1)
                color = Color3.fromHSV(0, 0, gray)
                alpha = 255
            elseif colorType == 2 then
                local r, g, b = unpack(row, i0, i1)
                color = Color3.fromRGB(r, g, b)
                alpha = 255
            elseif colorType == 3 then
                local palette = self.Palette
                local alphaData = self.AlphaData
                local index = unpack(row, i0, i1)
                index = index + 1
                if palette then
                    color = palette[index]
                end
                if alphaData then
                    alpha = alphaData[index]
                end
            elseif colorType == 4 then
                local gray, a = unpack(row, i0, i1)
                color = Color3.fromHSV(0, 0, gray)
                alpha = a
            elseif colorType == 6 then
                local r, g, b, a = unpack(row, i0, i1)
                color = Color3.fromRGB(r, g, b, a)
                alpha = a
            end
        end
        if not color then
            color = Color3.new()
        end
        if not alpha then
            alpha = 255
        end
        return color, alpha
    end
    function PNG.new(buffer)
        local reader = BinaryReader.new(buffer)
        local file = {
            Chunks = {};
            Metadata = {};
            Reading = true;
            ZlibStream = "";
        }
        local header = reader:ReadString(8)
        if header ~= "\137PNG\r\n\26\n" then
            error("PNG - Input data is not a PNG file.", 2)
        end
        while file.Reading do
            local length = reader:ReadInt32()
            local chunkType = reader:ReadString(4)
            local data, crc
            if length > 0 then
                data = reader:ForkReader(length)
                crc = reader:ReadUInt32()
            end
            local chunk = {
                Length = length;
                Type = chunkType;
                Data = data;
                CRC = crc;
            }
            local handler = chunks[chunkType]
            if handler then
                handler(file, chunk)
            end
            table.insert(file.Chunks, chunk)
        end
        local success, response = pcall(function ()
            local result = {}
            local index = 0
            Deflate:InflateZlib{
                Input = BinaryReader.new(file.ZlibStream);
                Output = function (byte)
                    index = index + 1
                    result[index] = string.char(byte)
                end
            }
            return table.concat(result)
        end)
        if not success then
            error("PNG - Unable to unpack PNG data. " .. tostring(response), 2)
        end
        local width = file.Width
        local height = file.Height
        local bitDepth = file.BitDepth
        local colorType = file.ColorType
        local buffer = BinaryReader.new(response)
        file.ZlibStream = nil
        local bitmap = {}
        file.Bitmap = bitmap
        local channels = getBytesPerPixel(colorType)
        file.NumChannels = channels
        local bpp = math.max(1, channels * (bitDepth / 8))
        file.BytesPerPixel = bpp
        for row = 1, height do
            local filterType = buffer:ReadByte()
            local scanline = buffer:ReadBytes(width * bpp, true)
            bitmap[row] = {}
            if filterType == 0 then
                Unfilter:None(scanline, bitmap, bpp, row)
            elseif filterType == 1 then
                Unfilter:Sub(scanline, bitmap, bpp, row)
            elseif filterType == 2 then
                Unfilter:Up(scanline, bitmap, bpp, row)
            elseif filterType == 3 then
                Unfilter:Average(scanline, bitmap, bpp, row)
            elseif filterType == 4 then
                Unfilter:Paeth(scanline, bitmap, bpp, row)
            end
        end
        return setmetatable(file, PNG)
    end
    return PNG
end

modules["modules.standard.jpeg.BitBuffer"] = function()
    local BitBuffer = {
        Bytes = "",
        Size = 0,
        ByteIndex = 0,
        CurrentByte = 0,
        Bit = 0
    }
    BitBuffer.__index = BitBuffer
    function BitBuffer.New(Data)
        local Buffer = setmetatable({}, BitBuffer)
        Buffer.Bytes = Data
        Buffer.Size = #Buffer.Bytes
        return Buffer
    end
    function BitBuffer:ReadBit()
        if (self.Bit == 0) then
            self.ByteIndex = self.ByteIndex + 1
            self.Bit = 0
            local NextByte = string.unpack(">I1", self.Bytes, self.ByteIndex)
            if (NextByte == 0x00 and self.CurrentByte == 0xFF) then
                self.ByteIndex = self.ByteIndex + 1
                NextByte = string.unpack(">I1", self.Bytes, self.ByteIndex)
            elseif (self.CurrentByte == 0xFF) then
                error("Unexpected marker in entropy stream: "..tostring(self.CurrentByte), 1)
            end
            self.CurrentByte = NextByte
        end
        local Bit = bit32.band(bit32.rshift(self.CurrentByte, 7 - self.Bit), 1)
        self.Bit = bit32.band(self.Bit + 1, 0x7)
        return Bit
    end
    function BitBuffer:ReadBits(NumBits)
        local Bits = 0
        for i = 1, NumBits, 1 do
            Bits = bit32.bor((bit32.lshift(Bits, 1)), self:ReadBit())
        end
        return Bits
    end
    function BitBuffer:ReadBytes(NumBytes)
        if (self.Bit ~= 0) then
            self:Align()
        end
        local Bytes = 0
        for i = 1, NumBytes, 1 do
            self.ByteIndex = self.ByteIndex + 1
            self.CurrentByte = string.unpack(">I1", self.Bytes, self.ByteIndex)
            Bytes = bit32.bor(bit32.lshift(Bytes, 8), self.CurrentByte)
        end
        return Bytes
    end
    function BitBuffer:Align()
        self.Bit = 0
    end
    function BitBuffer:IsEmpty()
        return self.Size <= self.ByteIndex
    end
    return BitBuffer
end

modules["modules.standard.jpeg.HuffmanTree"] = function()
    local HuffmanTree = {
        Root = {}
    }
    HuffmanTree.__index = HuffmanTree
    function HuffmanTree.New()
        local NewTree = setmetatable({}, HuffmanTree)
        NewTree.Root = {}
        return NewTree
    end
    function HuffmanTree:AddCode(Code, Bits, Value)
        local CurrentTable = self.Root
        for i = 1, Bits, 1 do
            local Bit = bit32.band(bit32.rshift(Code, Bits - i), 1)
            if (CurrentTable[Bit] == nil) then
                CurrentTable[Bit] = {}
            end
            CurrentTable = CurrentTable[Bit]
        end
        if (CurrentTable[0] ~= nil or CurrentTable[1] ~= nil or CurrentTable.Value ~= nil) then
            error("Attempt to add code that is a prefix of an already existing code", 1)
        end
        CurrentTable.Value = Value
    end
    function HuffmanTree:Index(Code, Bits)
        local CurrentTable = self.Root
        for i = 1, Bits, 1 do
            CurrentTable = CurrentTable[bit32.band(bit32.rshift(Code, Bits - i), 1)]
        end
        return CurrentTable.Value
    end
    return HuffmanTree
end

modules["modules.standard.jpeg.IDCT"] = function()
    local c1 = math.cos(math.pi / 16) / 2
    local c2 = math.cos(2 * math.pi / 16) / 2
    local c3 = math.cos(3 * math.pi / 16) / 2
    local c4 = math.cos(4 * math.pi / 16) / 2
    local c5 = math.cos(5 * math.pi / 16) / 2
    local c6 = math.cos(6 * math.pi / 16) / 2
    local c7 = math.cos(7 * math.pi / 16) / 2
    function IDCT(Data)
        for j = 1, 8, 1 do
            local k11 = (Data[j] + Data[32 + j]) * c4 + c2 * Data[16 + j] + c6 * Data[48 + j]
            local k21 = (Data[j] - Data[32 + j]) * c4 + c6 * Data[16 + j] - c2 * Data[48 + j]
            local k31 = (Data[j] - Data[32 + j]) * c4 - c6 * Data[16 + j] + c2 * Data[48 + j]
            local k41 = (Data[j] + Data[32 + j]) * c4 - c2 * Data[16 + j] - c6 * Data[48 + j]
            local k12 = c1 * Data[8 + j] + c3 * Data[24 + j] + c5 * Data[40 + j] + c7 * Data[56 + j]
            local k22 = c3 * Data[8 + j] - c7 * Data[24 + j] - c1 * Data[40 + j] - c5 * Data[56 + j]
            local k32 = c5 * Data[8 + j] - c1 * Data[24 + j] + c7 * Data[40 + j] + c3 * Data[56 + j]
            local k42 = c7 * Data[8 + j] - c5 * Data[24 + j] + c3 * Data[40 + j] - c1 * Data[56 + j]
            Data[j] = k11 + k12
            Data[8 + j] = k21 + k22
            Data[16 + j] = k31 + k32
            Data[24 + j] = k41 + k42
            Data[56 + j] = k11 - k12
            Data[48 + j] = k21 - k22
            Data[40 + j] = k31 - k32
            Data[32 + j] = k41 - k42
        end
        for i = 0, 56, 8 do
            local k11 = (Data[i + 1] + Data[i + 5]) * c4 + c2 * Data[i + 3] + c6 * Data[i + 7]
            local k21 = (Data[i + 1] - Data[i + 5]) * c4 + c6 * Data[i + 3] - c2 * Data[i + 7]
            local k31 = (Data[i + 1] - Data[i + 5]) * c4 - c6 * Data[i + 3] + c2 * Data[i + 7]
            local k41 = (Data[i + 1] + Data[i + 5]) * c4 - c2 * Data[i + 3] - c6 * Data[i + 7]
            local k12 = c1 * Data[i + 2] + c3 * Data[i + 4] + c5 * Data[i + 6] + c7 * Data[i + 8]
            local k22 = c3 * Data[i + 2] - c7 * Data[i + 4] - c1 * Data[i + 6] - c5 * Data[i + 8]
            local k32 = c5 * Data[i + 2] - c1 * Data[i + 4] + c7 * Data[i + 6] + c3 * Data[i + 8]
            local k42 = c7 * Data[i + 2] - c5 * Data[i + 4] + c3 * Data[i + 6] - c1 * Data[i + 8]
            Data[i + 1] = k11 + k12
            Data[i + 2] = k21 + k22
            Data[i + 3] = k31 + k32
            Data[i + 4] = k41 + k42
            Data[i + 8] = k11 - k12
            Data[i + 7] = k21 - k22
            Data[i + 6] = k31 - k32
            Data[i + 5] = k41 - k42
        end
    end
    return IDCT
end

modules["modules.standard.jpeg"] = function()
    local Buffer = drequire("modules.standard.jpeg.BitBuffer")
    local HuffmanTree = drequire("modules.standard.jpeg.HuffmanTree")
    local IDCT = drequire("modules.standard.jpeg.IDCT")

    local SOI = 0xD8
    local EOI = 0xD9
    local SOF0 = 0xC0
    local SOF1 = 0xC1
    local SOF2 = 0xC2
    local SOF3 = 0xC3
    local DHT = 0xC4
    local DQT = 0xDB
    local DAC = 0xCC
    local DRI = 0xDD
    local SOS = 0xDA
    local DNL = 0xDC
    local RSTnMin = 0xD0
    local RSTnMax = 0xD8
    local APPn = 0xE0
    local Comment = 0xFE
    local JFIFHeader = 0xE0

    local ZigZag = {
        1, 2, 6, 7, 15, 16, 28, 29,
        3, 5, 8, 14, 17, 27, 30, 43,
        4, 9, 13, 18, 26, 31, 42, 44,
        10, 12, 19, 25, 32, 41, 45, 54,
        11, 20, 24, 33, 40, 46, 53, 55,
        21, 23, 34, 39, 47, 52, 56, 61,
        22, 35, 38, 48, 51, 57, 60, 62,
        36, 37, 49, 50, 58, 59, 63, 64
    }
    function YCbCrToRGB(ImageInfo)
        local Pixels = ImageInfo.Pixels
        local Offset = ImageInfo.SamplePrecision > 0 and bit32.lshift(1, (ImageInfo.SamplePrecision - 1)) or 0
        local Max = Offset * 2 - 1
        local function Clamp(x)
            if (x > Max) then return Max end
            if (x < 0) then return 0 end
            return x
        end
        local Index = 1
        for i = 1, ImageInfo.Y, 1 do
            for j = 1, ImageInfo.X, 1 do
                local y = Pixels[1][Index]
                local Cb = Pixels[2][Index] - Offset
                local Cr = Pixels[3][Index] - Offset
                local R = Clamp(y + 1.402 * Cr)
                local G = Clamp(y - 0.34414 * Cb - 0.71414 * Cr)
                local B = Clamp(y + 1.772 * Cb)
                Pixels[1][Index] = math.floor(R + 0.5)
                Pixels[2][Index] = math.floor(G + 0.5)
                Pixels[3][Index] = math.floor(B + 0.5)
                Index = Index + 1
            end
        end
    end
    function ReadQuantizationTables(Buff, ImageInfo)
        local Length = Buff:ReadBytes(2) - 2
        while (Length > 0) do
            local Precision = Buff:ReadBits(4) == 0 and 1 or 2
            local Tq = Buff:ReadBits(4)
            local QuantizationTable = {}
            Length = Length - 1
            for v = 1, 64, 1 do
                QuantizationTable[v] = Buff:ReadBytes(Precision)
            end
            Length = Length - Precision * 64
            ImageInfo.QuantizationTables[Tq + 1] = QuantizationTable
        end
    end
    function ReadHuffmanTable(Buff, ImageInfo)
        local Length = Buff:ReadBytes(2) - 2
        while (Length > 0) do
            local TableClass = Buff:ReadBits(4)
            local Dest = Buff:ReadBits(4)
            local CodeLengths = {}
            local GeneratedHuffmanCodes = HuffmanTree.New()
            local CurrentCode = 0
            for i = 1, 16, 1 do
                CodeLengths[i] = Buff:ReadBytes(1)
            end
            Length = Length - 17
            for i = 1, 16, 1 do
                for j = 1, CodeLengths[i], 1 do
                    local Value = Buff:ReadBytes(1)
                    GeneratedHuffmanCodes:AddCode(CurrentCode, i, Value)
                    CurrentCode = CurrentCode + 1
                end
                Length = Length - CodeLengths[i]
                CurrentCode = bit32.lshift(CurrentCode, 1)
            end
            if (TableClass == 1) then
                ImageInfo.ACHuffmanCodes[Dest + 1] = GeneratedHuffmanCodes
            else
                ImageInfo.DCHuffmanCodes[Dest + 1] = GeneratedHuffmanCodes
            end
        end
    end
    function ReadJFIFHeader(Buff)
        local Length = Buff:ReadBytes(2)
        local Identfier = Buff:ReadBytes(5)
        if (Identfier ~= 0x4A46494600) then
            Buff:ReadBytes(Length - 7)
            return
        end
        local Version = Buff:ReadBytes(2)
        local Density = Buff:ReadBytes(1)
        local XDensity = Buff:ReadBytes(2)
        local YDensity = Buff:ReadBytes(2)
        local XThumbnail = Buff:ReadBytes(1)
        local YThumbnail = Buff:ReadBytes(1)
        Buff:ReadBytes(XThumbnail * YThumbnail)
    end
    function ReadFrame(Buff, ImageInfo)
        local Length = Buff:ReadBytes(2)
        local Precision = Buff:ReadBytes(1)
        ImageInfo.SamplePrecision = Precision
        ImageInfo.Y = Buff:ReadBytes(2)
        ImageInfo.X = Buff:ReadBytes(2)
        ImageInfo.HMax = 1
        ImageInfo.VMax = 1
        local ComponantsInFrame = Buff:ReadBytes(1)
        for i = 1, ComponantsInFrame, 1 do
            local Identifier = Buff:ReadBytes(1)
            local Componant = {
                HorizontalSamplingFactor = Buff:ReadBits(4),
                VerticalSamplingFactor = Buff:ReadBits(4),
                QuantizationTableDestination = Buff:ReadBytes(1)
            }
            if (Componant.HorizontalSamplingFactor > ImageInfo.HMax) then
                ImageInfo.HMax = Componant.HorizontalSamplingFactor
            end
            if (Componant.VerticalSamplingFactor > ImageInfo.VMax) then
                ImageInfo.VMax = Componant.VerticalSamplingFactor
            end
            ImageInfo.ComponantsInfo[Identifier] = Componant
            ImageInfo.Pixels[i] = {}
        end
        for p, c in pairs(ImageInfo.ComponantsInfo) do
            local BlocksXDim = math.ceil(math.ceil(ImageInfo.X / 8) * (c.HorizontalSamplingFactor / ImageInfo.HMax))
            local BlocksYDim = math.ceil(math.ceil(ImageInfo.Y / 8) * (c.VerticalSamplingFactor / ImageInfo.VMax))
            ImageInfo.Blocks[p] = {}
            ImageInfo.Blocks[p].X = BlocksXDim
            ImageInfo.Blocks[p].Y = BlocksYDim
            local NumComponantBlocks = BlocksXDim * BlocksYDim
            for i = 1, NumComponantBlocks, 1 do
                local Block = {}
                for v = 1, 64, 1 do
                    Block[v] = 0
                end
                ImageInfo.Blocks[p][i] = Block
            end
        end
    end
    function IndexHuffmanTree(Tree, Buff)
        local Current = Tree.Root
        while (Current.Value == nil) do
            Current = Current[Buff:ReadBit()]
        end
        return Current.Value
    end
    function Extend(V, T)
        if (T == 0) then return 0 end
        return V < bit32.lshift(1, (T - 1)) and V - bit32.lshift(1, T) + 1 or V
    end
    function ScanDimensions(ComponantsInScan, ComponantParameters, ImageInfo)
        local ScanHMax = 1
        local ScanVMax = 1
        for i = 1, ComponantsInScan, 1 do
            local ComponantParams = ComponantParameters[1]
            local ComponantInfo = ImageInfo.ComponantsInfo[ComponantParams.ScanComponantIndex]
            if (ComponantInfo.HorizontalSamplingFactor > ScanHMax) then
                ScanHMax = ComponantInfo.HorizontalSamplingFactor
            end
            if (ComponantInfo.VerticalSamplingFactor > ScanVMax) then
                ScanVMax = ComponantInfo.VerticalSamplingFactor
            end
        end
        local MCUXDim = math.ceil(ImageInfo.X / (8 * ScanHMax))
        local MCUYDim = math.ceil(ImageInfo.Y / (8 * ScanVMax))
        local TotalMCUs
        if (ComponantsInScan > 1) then
            TotalMCUs = MCUXDim * MCUYDim
        else
            local CInfo = ImageInfo.ComponantsInfo[ComponantParameters[1].ScanComponantIndex]
            TotalMCUs = math.max(CInfo.HorizontalSamplingFactor, math.ceil(math.ceil(ImageInfo.X * CInfo.HorizontalSamplingFactor / ImageInfo.HMax) / 8)) *
                math.max(CInfo.VerticalSamplingFactor, math.ceil(math.ceil(ImageInfo.Y * CInfo.VerticalSamplingFactor / ImageInfo.VMax) / 8))
        end
        return MCUXDim, TotalMCUs
    end
    function ReadSpectralScan(Buff, Ss, Se, Al, Ah, ComponantsInScan, ComponantParameters, ImageInfo)
        local MCUXDim, TotalMCUs = ScanDimensions(ComponantsInScan, ComponantParameters, ImageInfo)
        local RestartInterval = ImageInfo.RestartInterval
        local PreviousDCCoefficients = {}
        local EndOfBandRun = 0
        for i = 1, ComponantsInScan, 1 do
            PreviousDCCoefficients[i] = 0
        end
        for MCU = 1, TotalMCUs, 1 do
            for i = 1, ComponantsInScan, 1 do
                local ComponantParams = ComponantParameters[i]
                local ComponantInfo = ImageInfo.ComponantsInfo[ComponantParams.ScanComponantIndex]
                local ACHuffmanTree = ImageInfo.ACHuffmanCodes[ComponantParams.ACTableIndex + 1]
                local DCHuffmanTree = ImageInfo.DCHuffmanCodes[ComponantParams.DCTableIndex + 1]
                local NumComponantBlocks = ComponantsInScan > 1 and ComponantInfo.HorizontalSamplingFactor * ComponantInfo.VerticalSamplingFactor or 1
                for c = 1, NumComponantBlocks, 1 do
                    if (EndOfBandRun > 0 and EndOfBandRun - (NumComponantBlocks - c + 1) >= 0) then
                        EndOfBandRun = EndOfBandRun - (NumComponantBlocks - c + 1)
                        break
                    else
                        c = c + EndOfBandRun
                        EndOfBandRun = 0
                    end
                    local BlockData
                    local K = Ss + 1
                    local BlocksXDim = ImageInfo.Blocks[ComponantParams.ScanComponantIndex].X
                    local BlocksYDim = ImageInfo.Blocks[ComponantParams.ScanComponantIndex].Y
                    if (ComponantsInScan > 1) then
                        local MCUYIndex = (MCU-1) // MCUXDim
                        local MCUXIndex = (MCU-1) - MCUYIndex * MCUXDim
                        local BlockY = MCUYIndex * ComponantInfo.VerticalSamplingFactor + (c-1) // ComponantInfo.HorizontalSamplingFactor
                        local BlockX = MCUXIndex * ComponantInfo.HorizontalSamplingFactor + ((c-1) % ComponantInfo.HorizontalSamplingFactor) + 1
                        if (BlockX <= BlocksXDim and BlockY <= BlocksYDim) then
                            BlockData = ImageInfo.Blocks[ComponantParams.ScanComponantIndex][BlockY * BlocksXDim + BlockX]
                        end
                    else
                        local MCUYIndex = (MCU-1) // BlocksXDim
                        local MCUXIndex = (MCU-1) - MCUYIndex * BlocksXDim
                        if (MCUXIndex <= BlocksXDim and MCUYIndex <= BlocksYDim) then
                            BlockData = ImageInfo.Blocks[ComponantParams.ScanComponantIndex][MCU]
                        end
                    end
                    if (BlockData == nil) then
                        BlockData = {}
                        for l = 1, 64, 1 do
                            BlockData[l] = 0
                        end
                    end
                    if (Ss == 0) then
                        local T = IndexHuffmanTree(DCHuffmanTree, Buff)
                        local DIFF = Extend(Buff:ReadBits(T), T) + PreviousDCCoefficients[i]
                        PreviousDCCoefficients[i] = DIFF
                        BlockData[K] = BlockData[K] + DIFF * bit32.lshift(1, Al)
                        K = K + 1
                    end
                    while (K <= Se + 1) do
                        local RS = IndexHuffmanTree(ACHuffmanTree, Buff)
                        local LowerNibble = bit32.band(RS, 0xF)
                        local HigherNibble = bit32.rshift(RS, 4)
                        if (LowerNibble == 0) then
                            if (HigherNibble == 15) then
                                K = K + 16
                            else
                                EndOfBandRun = bit32.lshift(1, HigherNibble) + Buff:ReadBits(HigherNibble) - 1
                                break
                            end
                        else
                            K = K + HigherNibble
                            BlockData[K] = BlockData[K] + Extend(Buff:ReadBits(LowerNibble), LowerNibble) * bit32.lshift(1, Al)
                            K = K + 1
                        end
                    end
                end
            end
            if (RestartInterval ~= 0 and MCU % RestartInterval == 0 and MCU ~= TotalMCUs) then
                Buff:Align()
                local ExpextedMarker = 0xFF00 + RSTnMin + (((MCU - RestartInterval) // RestartInterval) % 8)
                local Marker = Buff:ReadBytes(2)
                if (Marker ~= ExpextedMarker) then
                    return
                end
                EndOfBandRun = 0
                for i = 1, ComponantsInScan, 1 do
                    PreviousDCCoefficients[i] = 0
                end
            end
        end
    end
    function ReadRefinementScan(Buff, Ss, Se, Al, Ah, ComponantsInScan, ComponantParameters, ImageInfo)
        local EndOfBandRun = 0
        local RestartInterval = ImageInfo.RestartInterval
        local Positive = bit32.lshift(1, Al)
        local Negative = -1 * Positive
        local MCUXDim, TotalMCUs = ScanDimensions(ComponantsInScan, ComponantParameters, ImageInfo)
        for MCU = 1, TotalMCUs, 1 do
            for i = 1, ComponantsInScan, 1 do
                local ComponantParams = ComponantParameters[i]
                local ComponantInfo = ImageInfo.ComponantsInfo[ComponantParams.ScanComponantIndex]
                local ACHuffmanTree = ImageInfo.ACHuffmanCodes[ComponantParams.ACTableIndex + 1]
                local NumComponantBlocks = ComponantsInScan > 1 and ComponantInfo.HorizontalSamplingFactor * ComponantInfo.VerticalSamplingFactor or 1
                for c = 1, NumComponantBlocks, 1 do
                    local BlockData
                    local K = Ss + 1
                    local BlocksXDim = ImageInfo.Blocks[ComponantParams.ScanComponantIndex].X
                    local BlocksYDim = ImageInfo.Blocks[ComponantParams.ScanComponantIndex].Y
                    if (ComponantsInScan > 1) then
                        local MCUYIndex = (MCU-1) // MCUXDim
                        local MCUXIndex = (MCU-1) - MCUYIndex * MCUXDim
                        local BlockY = MCUYIndex * ComponantInfo.VerticalSamplingFactor + (c-1) // ComponantInfo.HorizontalSamplingFactor
                        local BlockX = MCUXIndex * ComponantInfo.HorizontalSamplingFactor + ((c-1) % ComponantInfo.HorizontalSamplingFactor) + 1
                        if (BlockX <= BlocksXDim and BlockY <= BlocksYDim) then
                            BlockData = ImageInfo.Blocks[ComponantParams.ScanComponantIndex][BlockY * BlocksXDim + BlockX]
                        end
                    else
                        local MCUYIndex = (MCU-1) // BlocksXDim
                        local MCUXIndex = (MCU-1) - MCUYIndex * BlocksXDim
                        if (MCUXIndex <= BlocksXDim and MCUYIndex <= BlocksYDim) then
                            BlockData = ImageInfo.Blocks[ComponantParams.ScanComponantIndex][MCU]
                        end
                    end
                    if (BlockData == nil) then
                        BlockData = {}
                        for l = 1, 64, 1 do
                            BlockData[l] = 0
                        end
                    end
                    if (Ss == 0 and EndOfBandRun == 0) then
                        local Bit = Buff:ReadBit()
                        if (BlockData[K] == 0) then
                            BlockData[K] = (Bit == 0 and Negative or Positive)
                        else
                            BlockData[K] = BlockData[K] + (BlockData[K] < 0 and Negative or Positive)
                        end
                        K = K + 1
                        if (Se ~= 0) then error("invalid refinement scan, DC and AC coeffecients are mixed") end
                    end
                    while (K <= Se + 1 and EndOfBandRun == 0) do
                        local RS = IndexHuffmanTree(ACHuffmanTree, Buff)
                        local LowerNibble = bit32.band(RS, 0xF)
                        local HigherNibble = bit32.rshift(RS, 4)
                        if (LowerNibble == 0) then
                            if (HigherNibble == 15) then
                                local Skip = 16
                                while (Skip > 0 and K <= Se+1) do
                                    if (BlockData[K] ~= 0) then
                                        BlockData[K] = BlockData[K] + Buff:ReadBit() * (BlockData[K] < 0 and Negative or Positive)
                                    else
                                        Skip = Skip - 1
                                    end
                                    K = K + 1
                                end
                            else
                                EndOfBandRun = bit32.lshift(1, HigherNibble) + Buff:ReadBits(HigherNibble)
                                break
                            end
                        else
                            local Skip = HigherNibble
                            local Sign = Buff:ReadBits(LowerNibble) == 1 and 1 or -1
                            while ((Skip > 0 or BlockData[K] ~= 0) and K <= Se+1) do
                                if (BlockData[K] ~= 0) then
                                    BlockData[K] = BlockData[K] + Buff:ReadBit() * (BlockData[K] < 0 and Negative or Positive)
                                else
                                    Skip = Skip - 1
                                end
                                K = K + 1
                            end
                            if (K > Se + 1) then break end
                            BlockData[K] = BlockData[K] + Sign * bit32.lshift(1, Al)
                            K = K + 1
                        end
                    end
                    if (EndOfBandRun > 0) then
                        while (K <= Se + 1) do
                            if (BlockData[K] ~= 0) then
                                BlockData[K] = BlockData[K] + bit32.lshift(Buff:ReadBit(), Al) * (BlockData[K] < 0 and -1 or 1)
                            end
                            K = K + 1
                        end
                        EndOfBandRun = EndOfBandRun - 1
                    end
                end
            end
            if (ImageInfo.RestartInterval ~= 0 and MCU % ImageInfo.RestartInterval == 0 and MCU ~= TotalMCUs) then
                Buff:Align()
                local ExpextedMarker = 0xFF00 + RSTnMin + (((MCU - RestartInterval) // RestartInterval) % 8)
                local Marker = Buff:ReadBytes(2)
                if (Marker ~= ExpextedMarker) then
                    return
                end
                EndOfBandRun = 0
            end
        end
    end
    function ReadScan(Buff, ImageInfo)
        local Length = Buff:ReadBytes(2)
        local ComponantsInScan = Buff:ReadBytes(1)
        local ComponantParameters = {}
        for i = 1, ComponantsInScan, 1 do
            local Parameters = {
                ScanComponantIndex = Buff:ReadBytes(1),
                DCTableIndex = Buff:ReadBits(4),
                ACTableIndex = Buff:ReadBits(4)
            }
            ComponantParameters[i] = Parameters
        end
        local Ss = Buff:ReadBytes(1)
        local Se = Buff:ReadBytes(1)
        local Ah = Buff:ReadBits(4)
        local Al = Buff:ReadBits(4)
        if (Ah == 0) then
            ReadSpectralScan(Buff, Ss, Se, Al, Ah, ComponantsInScan, ComponantParameters, ImageInfo)
        else
            ReadRefinementScan(Buff, Ss, Se, Al, Ah, ComponantsInScan, ComponantParameters, ImageInfo)
        end
        task.wait()
    end
    function ReadRestartInterval(Buff, ImageInfo)
        local Length = Buff:ReadBytes(2)
        ImageInfo.RestartInterval = Buff:ReadBytes(2)
    end
    function ReadDNL(Buff)
        local Length = Buff:ReadBytes(2)
        local NumLines = Buff:ReadBytes(2)
    end
    function InterpretMarker(Buff, ImageInfo)
        local Marker = Buff:ReadBytes(1)
        if (Marker == DQT) then
            ReadQuantizationTables(Buff, ImageInfo)
        elseif (Marker == DHT) then
            ReadHuffmanTable(Buff, ImageInfo)
        elseif (Marker == JFIFHeader) then
            ReadJFIFHeader(Buff)
        elseif (Marker == SOF0 or Marker == SOF1 or Marker == SOF2) then
            ReadFrame(Buff, ImageInfo)
        elseif (Marker == SOS) then
            ReadScan(Buff, ImageInfo)
            Buff:Align()
        elseif (Marker == DRI) then
            ReadRestartInterval(Buff, ImageInfo)
        elseif (Marker == EOI) then
            return -1
        elseif (Marker == DAC) then
            error("Arithmetic encoding is not supported")
        elseif (Marker == DNL) then
            ReadDNL(Buff)
            error("DNL currently unsupported")
        elseif (Marker ~= 0) then
            local Len = Buff:ReadBytes(2) - 2
            if (SOF2 < Marker and Marker <= 0xCF) then
                error("Unsupported frame:", Marker)
            end
            Buff:ReadBytes(Len)
        end
    end
    function TransformBlocks(ImageInfo)
        local Blocks = ImageInfo.Blocks
        local Pixels = ImageInfo.Pixels
        local X = ImageInfo.X
        local Y = ImageInfo.Y
        for c, info in pairs(ImageInfo.ComponantsInfo) do
            local QuantizationTable = ImageInfo.QuantizationTables[info.QuantizationTableDestination+1]
            local XScale = ImageInfo.HMax // info.HorizontalSamplingFactor
            local YScale = ImageInfo.VMax // info.VerticalSamplingFactor
            local SubImageX = XScale * 8
            local SubImageY = YScale * 8
            for yb = 1, Blocks[c].Y, 1 do
                for xb = 1, Blocks[c].X, 1 do
                    local BlockIndex = (yb - 1) * Blocks[c].X + xb
                    local DecodedBlock = Blocks[c][BlockIndex]
                    local Block = {}
                    for v = 1, 64, 1 do
                        Block[v] = DecodedBlock[ZigZag[v]] * QuantizationTable[ZigZag[v]]
                    end
                    IDCT(Block)
                    local Offset = ImageInfo.SamplePrecision > 0 and bit32.lshift(1, (ImageInfo.SamplePrecision - 1)) or 0
                    for v = 1, 64, 1 do
                        Block[v] = Block[v] + Offset
                    end
                    local HorizontalEdge = math.min(SubImageY, (Y - ((yb - 1) * SubImageY)))
                    local VerticalEdge = math.min(SubImageX, (X - ((xb - 1) * SubImageX)))
                    local ImageYIndex = (yb - 1) * SubImageY * X
                    local ImageXIndex = (xb - 1) * SubImageX
                    for y = 1, HorizontalEdge, 1 do
                        local BlockYIndex = (y - 1) // YScale
                        for x = 1, VerticalEdge, 1 do
                            local BlockXIndex = (x - 1) // XScale
                            Pixels[c][ImageYIndex + ImageXIndex + 1] = Block[BlockYIndex * 8 + BlockXIndex + 1]
                            ImageXIndex = ImageXIndex + 1
                        end
                        ImageXIndex = ImageXIndex - VerticalEdge
                        ImageYIndex = ImageYIndex + X
                    end
                end
            end
        end
    end
    function DecodeJpeg(BString)
        local Buff = Buffer.New(BString)
        if (Buff:ReadBytes(2) ~= 0xFF00 + SOI) then return nil end
        local ImageInfo = {
            X = 0,
            Y = 0,
            Pixels = {},
            QuantizationTables = {{}, {}, {}, {}},
            DCHuffmanCodes = {{}, {}, {}, {}},
            ACHuffmanCodes = {{}, {}, {}, {}},
            ComponantsInfo = {},
            HMax = 0,
            VMax = 0,
            SamplePrecision = 0,
            RestartInterval = 0,
            Blocks = {}
        }
        while (not Buff:IsEmpty()) do
            local Byte = Buff:ReadBytes(1)
            if (Byte == 0xFF) then
                local R = InterpretMarker(Buff, ImageInfo)
                if (R == -1) then
                    break
                end
            end
        end
        TransformBlocks(ImageInfo)
        YCbCrToRGB(ImageInfo)
        ImageInfo.Blocks = nil
        return ImageInfo
    end
    return {decode=DecodeJpeg}
end

modules["modules.standard.universal_image_loader"] = function()
    local PNG = drequire("modules.standard.png")
    local JPEG = drequire("modules.standard.jpeg")
    local UniversalImage = {}
    UniversalImage.__index = UniversalImage
    local function createPNGWrapper(pngImage)
        local wrapper = {
            Width = pngImage.Width,
            Height = pngImage.Height,
            _type = "PNG",
            _pngImage = pngImage
        }
        function wrapper:GetPixel(x, y)
            local color, alpha = self._pngImage:GetPixel(x, y)
            return color, (alpha or 255) / 255
        end
        return setmetatable(wrapper, UniversalImage)
    end
    local function createJPEGWrapper(jpegImage)
        local wrapper = {
            Width = jpegImage.X,
            Height = jpegImage.Y,
            _type = "JPEG",
            _jpegImage = jpegImage
        }
        function wrapper:GetPixel(x, y)
            local index = (y - 1) * self.Width + x
            local r = self._jpegImage.Pixels[1][index] or 0
            local g = self._jpegImage.Pixels[2][index] or 0
            local b = self._jpegImage.Pixels[3][index] or 0
            local color = Color3.fromRGB(r, g, b)
            return color, 1
        end
        return setmetatable(wrapper, UniversalImage)
    end
    function UniversalImage.load(fileData, formatHint)
        local isPNG = string.sub(fileData, 1, 8) == "\137PNG\r\n\26\n"
        local isJPEG = string.sub(fileData, 1, 2) == "\255\216"
        if not isPNG and not isJPEG then
            if formatHint == "PNG" then
                isPNG = true
            elseif formatHint == "JPEG" or formatHint == "JPG" then
                isJPEG = true
            else
                return nil, "Unknown format"
            end
        end
        if isPNG then
            local pngImage = PNG.new(fileData)
            return createPNGWrapper(pngImage)
        elseif isJPEG then
            local jpegImage = JPEG.decode(fileData)
            if not jpegImage then
                return nil, "JPEG decode failed"
            end
            return createJPEGWrapper(jpegImage)
        else
            return nil, "Unsupported format"
        end
    end
    return UniversalImage
end

-- 注意：原脚本中还有 modules["modules.uilibs.image_source_selector"] 和 modules["modules.drawme.canvas"]，我们不再需要，故删除。

-- ======================== 自定义画布获取函数 ========================

local function getCanvas()
    local Players = Services.Players
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return nil end
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    -- 使用与原脚本相同的搜索逻辑（从实例中查找 RenderImageLabel）
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("ImageLabel") and v.Name == "RenderImageLabel" then
            if v.ImageContent and v.ImageContent.SourceType == Enum.ContentSourceType.Object then
                local editableImage = v.ImageContent.Object
                if editableImage and editableImage:IsA("EditableImage") then
                    return editableImage
                end
            end
        end
    end
    return nil
end

-- ======================== 内部辅助函数 ========================

local function readFile(path)
    if readfile then
        local success, content = pcall(readfile, path)
        if success and content then return content, true end
        return nil, false
    end
    local file, err = io.open(path, "rb")
    if not file then return nil, false end
    local content = file:read("*all")
    file:close()
    return content, true
end

local function httpGet(url)
    local request_func = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if request_func then
        local response = request_func({Url = url, Method = "GET"})
        if response.StatusCode == 200 and response.Body then
            return response.Body, true
        end
        return nil, false
    else
        local success, result = pcall(function()
            return cloneref(game):HttpGet(url)
        end)
        if success and result then
            return result, true
        end
        return nil, false
    end
end

-- ======================== 主模块 ========================

local image_loader = drequire("modules.standard.universal_image_loader")

local Drawme = {}

--- 加载并绘制图像到 EditableImage 画布
--- @param source string 本地路径或网络URL
--- @return number errCode
function Drawme.loadAndDraw(source)
    if not source or type(source) ~= "string" then
        return 2  -- 无效参数当作文件错误
    end

    -- 1. 获取画布
    local targetImage = getCanvas()
    if not targetImage then
        return 1
    end

    -- 2. 读取数据
    local fileData
    local isURL = source:match("^https?://")
    if isURL then
        local success
        fileData, success = httpGet(source)
        if not success or not fileData then
            return 3
        end
    else
        local success
        fileData, success = readFile(source)
        if not success or not fileData then
            return 2
        end
    end

    -- 3. 解码
    local success, image = pcall(function()
        return image_loader.load(fileData)
    end)
    if not success or not image then
        return 4
    end

    -- 4. 绘制
    local canvasSize = targetImage.Size
    local dstWidth, dstHeight = canvasSize.X, canvasSize.Y
    local srcWidth, srcHeight = image.Width, image.Height
    local bufferSize = dstWidth * dstHeight * 4
    local pixelBuffer = buffer.create(bufferSize)  -- 使用全局 buffer
    local ratioX = srcWidth / dstWidth
    local ratioY = srcHeight / dstHeight
    local pointer = 0
    for y = 1, dstHeight do
        local sampleY = math.floor((y - 1) * ratioY) + 1
        if sampleY > srcHeight then sampleY = srcHeight end
        for x = 1, dstWidth do
            local sampleX = math.floor((x - 1) * ratioX) + 1
            if sampleX > srcWidth then sampleX = srcWidth end
            local color, alpha = image:GetPixel(sampleX, sampleY)
            local aVal = alpha or 1
            buffer.writeu8(pixelBuffer, pointer,     math.floor(color.R * 255))
            buffer.writeu8(pixelBuffer, pointer + 1, math.floor(color.G * 255))
            buffer.writeu8(pixelBuffer, pointer + 2, math.floor(color.B * 255))
            buffer.writeu8(pixelBuffer, pointer + 3, math.floor(aVal * 255))
            pointer = pointer + 4
        end
    end

    local writeSuccess, writeErr = pcall(function()
        targetImage:WritePixelsBuffer(Vector2.zero, canvasSize, pixelBuffer)
    end)
    if not writeSuccess then
        return 5
    end

    return 0
end

return Drawme