--!native
--!optimize 2

unloadTHub = nil

ConfigModule.setmain("THubConfig")
mainConfig = ConfigModule.createconfig("main")
musicList = ConfigModule.createmusicconfig("music")
data = {
    basicdata = {
        window = {
            windowSize = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) and UDim2.new(0, 476, 0, 294) or UDim2.new(0, 680, 0, 420),
        },
        player = {
            name = LocalPlayer.Name,
            displayname = LocalPlayer.DisplayName,
            userid = LocalPlayer.UserId,
            isPremium = (LocalPlayer.MembershipType == Enum.MembershipType.Premium),

            speed = ((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) or {WalkSpeed = 16}).WalkSpeed, islockspeed = false,
            jump = ((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) or {JumpPower = 50}).JumpPower, islockjump = false,
            maxhealth = ((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) or {JumpPower = 100}).MaxHealth, islockmaxhealth = false,
            health = ((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) or {JumpPower = 100}).Health, islockhealth = false,
            gravity = Workspace.Gravity, islockgravity = false,
        },
        releasetools = {
            antiafk = true,
            zoom = ZoomModule.new(),
            Lantern = PlayerLightModule.new({ Brightness = 3, Range = 20, Color = Color3.fromRGB(255, 165, 0), Shadows = true }),
            SuperLighter = PlayerLightModule.new({ Brightness = 2, Range = 1000 }),
            noclip = false,
            infjump = false,
            antifall = false,
            antidead = false,
            executecode = "",
            nightvision = false,
            npc = NPCHighLighter.new(),
            chatresend = false,
            supernightvision = false,
            originalBrightness = Lighting.Brightness,
            originalExposureCompensation = Lighting.ExposureCompensation,
            keepthub = false,
            networkpausedisable = false,
            exitgame = 0,
            staffcheck = false,
            xray = false,
            spawnpos,
            lastDeath,
        },
        otherdata = {
            yiyan = HttpService:JSONDecode(AsyncFileFetcher.fetchSingle("https://api.52vmy.cn/api/wl/yan/yiyan")),
            executordetecter = {
                robloxinfo = HttpService:JSONDecode(AsyncFileFetcher.fetchSingle("https://weao.xyz/api/versions/current")),
                exploits = HttpService:JSONDecode(AsyncFileFetcher.fetchSingle("https://weao.xyz/api/status/exploits")),
            },
            playertitle = {
                tag = ChatTagModule.new({
                    player = LocalPlayer,
                    text = "[VIP]",
                    color = "#FFD700",
                    size = 18,
                    bold = false,
                    italic = false,
                    font = "GothamBlack",
                }),
                text = "[VIP]",
                color = "#FFD700",
                size = 18,
                bold = false,
                italic = false,
                font = "GothamBlack",
            },
            musicbox = Instance.new("Sound"),
            testSound = Instance.new("Sound"),
            daySettings = {
                ClockTime = 14,
                GeographicLatitude = 41.73,
            },
            nightSettings = {
                ClockTime = 2,
                GeographicLatitude = 41.73,
            },
            musicData = {
                isPlay = false,
                isPause = false,
                PlayLocation = 0,
                currentId = "142376088",
                othermusicname = "",
                musicIds = {
                    "142376088", "1844108188", "1846368080", "5409360995", "1848354536", "1841647093",
                    "1837879082", "1837768517", "9041745502", "9048375035", "1840684208",
                    "118939739460633", "1846999567", "1840434670", "9046863253", "1848028342",
                    "1843404009", "1845756489", "1846862303", "1841998846", "122600689240179",
                    "1837101327", "125793633964645", "1846088038", "1845554017", "1838635121",
                    "16190757458", "1846442964", "1839703786", "1839444520", "1838028467",
                    "7028518546", "121336636707861", "87540733242308", "1838667168", "1838667680",
                    "1845179120", "136598811626191", "79451196298919", "1837769001", "103086632976213",
                    "120817494107898", "5410084188", "104483584177040", "7024220835", "1842976958",
                    "7023635858", "1835782117", "7029024726", "7029017448", "5410085694",
                    "1843471292", "7029005367", "131020134622685", "7024340270", "1836057733",
                    "9047104336", "9047104411", "1843324336", "1845215540"
                },
            },
            audioData = {
                enable = false,
                threshold = 30,
                currentSelectedId = nil,
                isTesting = false,
                audioListItems = {},
                lastScanTime = 0,
                scanConnection = nil,
            },
            autoconnirc = mainConfig.autoconnirc and mainConfig.autoconnirc or false,
        },
        hankermodule = {
            hkill = {
                killname = "",
                killrange = 100,
                killall = false,
                killany = false,
            },
            spin = {
                speed = 20,
            },
        },
    },
    scriptlist = {
        { name = "高级聊天系统", link = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/customChatSystem.lua" },
        { name = "飞行V4", link = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/FlyV4.lua" },
        { name = "IY5.5.9(指令挂)(汉化版)", link = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/IY.lua" },
        { name = "Dex", link = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua" },
        { name = "DexDark", link = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/DexDark.lua" },
        { name = "SimpleSpy", link = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/simplespyv3.lua" },
        { name = "NPC自瞄", link = "https://rawscripts.net/raw/Universal-Script-Npc-Aimbot-64954" },
        { name = "SolaraHub", link = "https://raw.githubusercontent.com/samuraa1/Solara-Hub/refs/heads/main/SH.lua" },
        { name = "XAHub", link = "https://raw.githubusercontent.com/XiaoLuau/Script/main/Loader.lua" },
        { name = "控制NPC", link = "https://raw.githubusercontent.com/randomstring0/fe-source/refs/heads/main/NPC/source/main.Luau" },
        { name = "控制东西", link = "https://pastebin.com/raw/VVWcfs9t" },
        { name = "OldMSPaint", link = "https://raw.githubusercontent.com/notpoiu/mspaint/main/main.lua" },
        { name = "Doors扫描器", link = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/DoorsNVC3000.lua" },
        { name = "玩家控制", link = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/PlayerControl.lua" },
        { name = "动画中心", link = "https://raw.githubusercontent.com/GamingScripter/Animation-Hub/main/Animation%20Gui" },
        { name = "阿尔宙斯", link = "https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20X%20V3" },
        { name = "VChine V2", link = "https://pastebin.com/raw/SuDKzFKD" },
    },
    Supported_Games = {
        { gameid = 2162087722, name = "兽化项目" },
        { gameid = 6508759464, name = "格蕾丝" },
        { gameid = 5166944221, name = "死亡球" },
        { gameid = 9161105297, name = "小屋角色扮演" },
        { gameid = 6352299542, name = "妄想办公室" },
        { gameid = 972475338,  name = "南极探险队" },
        { gameid = 6996099240, name = "噩梦之行" },
        { gameid = 5265348926, name = "西部森林" },
        { gameid = 5429450445, name = "警笛头:遗产" },
        { gameid = 4981761600, name = "深渊" },
        { gameid = 8111911783, name = "后院生存" },
        { gameid = 5974510967, name = "最黑暗的时刻" },
        { gameid = 1709917610, name = "后悔电梯" },
    },
    othergamedata = {
        west_wood = {
            monster = NameTagModule.new("WendigoAI", "fuzzy", 20, true, "怪物")
        },
        sirenhead_legacy = {
            cratemodule = HighlightModule.new("crate", "fuzzy", "item"),
            cratenametagmodule = NameTagModule.new("crate", "fuzzy", 20, true, "盒子"),
            berrymodule = HighlightModule.new("berry", "fuzzy", "item"),
            berrynametagmodule = NameTagModule.new("berry", "fuzzy", 20, true, "浆果"),
        },
        nightmare_run = {
            monster = MovableHighlighter_NM.new(),
            HLCheese = HighlightModule.new("Cheese", "fuzzy", "item"),
        },
        project_transfur = {
            bot = HighlightModule.new("Bot", "fuzzy", "item"),
            botnt = NameTagModule.new("Bot", "fuzzy", 20, true, "Bot兽"),
            smallsafe = HighlightModule.new("__BasicSmallSafe", "fuzzy", "item"),
            smallsafent = NameTagModule.new("__BasicSmallSafe", "fuzzy", 20, true, "小保险箱"),
            largesafe = HighlightModule.new("__BasicLargeSafe", "fuzzy", "item"),
            largesafent = NameTagModule.new("__BasicLargeSafe", "fuzzy", 20, true, "大保险箱"),
            goldensafe = HighlightModule.new("__LargeGoldenSafe", "fuzzy", "item"),
            goldensafent = NameTagModule.new("__LargeGoldenSafe", "fuzzy", 20, true, "金保险箱"),
            crate = HighlightModule.new("Surplus Crate", "fuzzy", "item"),
            cratent = NameTagModule.new("Surplus Crate", "fuzzy", 20, true, "武器盒"),
            sd = HighlightModule.new("SupplyDrop", "fuzzy", "item"),
            sdnt = NameTagModule.new("SupplyDrop", "fuzzy", 20, true, "空投"),
        },
        delesions_office = {
            entitywarning = false,
            tipotherplayer = false,
            auto013 = false,
            entitys = {
                NormalEntity = { name = "EN-001", tip = "立刻躲在柜子中！" },
                NormalEntityType2 = { name = "EN-001-02", tip = "立刻躲在柜子中！" },
                SnakeEntity = { name = "EN-002", tip = "多待在柜子里一会！" },
                TrainEntity = { name = "EN-003", tip = "不要犹豫，立刻躲起来！" },
                LateEntity = { name = "EN-004", tip = "稍后躲在柜子中！" },
                ReboundingEntity = { name = "EN-005", tip = "把握住进柜子的时间，他会来回冲！" },
                PeaceEntity = { name = "EN-006", tip = "千万不要躲在柜子中！" },
                VisionEntity = { name = "EN-007", tip = "不要躲在墙壁后！" },
                FocusEntity = { name = "EN-008", tip = "躲在柜子中，记住钥匙的位置！" },
                ShadowEntity = { name = "EN-011", tip = "他在黑暗中，不要看他！" },
                GhostEntity = { name = "EN-012", tip = "注意他的规则！" },
                UnknownEntity = { name = "EN-013", tip = "快点输入 'staycalmstayfocused'"},
                ChaserEntity = { name = "EN-015", tip = "快跑！" },
                DelmonEntity = { name = "EN-0??", tip = "暂未收录该数据" },
                DoorcamperEntity = { name = "EN-017", tip = "多注意门后！" }
            },
        },
        grace = {
            autolever = false,
            deleteentity = false,
        },
        backroomsurvival = {
            Shrieker = HighlightModule.new("Shrieker", "fuzzy", "hostileNpc"),
            Shriekernt = NameTagModule.new("Shrieker", "fuzzy", 20, true, "[敌对] 瞎子"),
            Wretch = HighlightModule.new("Wretch", "fuzzy", "hostileNpc"),
            Wretchnt = NameTagModule.new("Wretch", "fuzzy", 20, true, "[敌对] 悲尸"),
            Phantom = HighlightModule.new("Phantom", "fuzzy", "hostileNpc"),
            Phantomnt = NameTagModule.new("Phantom", "fuzzy", 20, true, "[敌对] 梦魇"),
            Bacteria = HighlightModule.new("Bacteria", "fuzzy", "hostileNpc"),
            Bacteriant = NameTagModule.new("Bacteria", "fuzzy", 20, true, "[敌对] 细菌"),
            SkinStealer = HighlightModule.new("Skin Stealer", "fuzzy", "hostileNpc"),
            SkinStealernt = NameTagModule.new("Skin Stealer", "fuzzy", 20, true, "[敌对] 窃皮者"),
            Recon = HighlightModule.new("Recon", "fuzzy", "neutralNpc"),
            Reconnt = NameTagModule.new("Recon", "fuzzy", 20, true, "[中立] 侦察兵"),
            Mechanic = HighlightModule.new("Mechanic", "fuzzy", "neutralNpc"),
            Mechanicnt = NameTagModule.new("Mechanic", "fuzzy", 20, true, "[中立] 修理工"),
        },
        AntarcticExpedition = {
            giftnumber = 0
        },
        DarkestHours = {
            Collectible = HighlightModule.new("Scrap", "fuzzy", "item"),
            Collectiblent = NameTagModule.new("Scrap", "fuzzy", 20, true, "[收集物]"),
        },
        Regretevator = {
            coins = HighlightModule.new("Coin", "pathFuzzy", "normal"),
            coinsnt = NameTagModule.new("Coin", "fuzzy", 20, false, "硬币"),
            bugbo_rocks = HighlightModule.new({"bugbo", "Rocks"}, "pathFuzzy", "item"),
            bugbo_rocksnt = NameTagModule.new({"bugbo", "Rocks"}, "pathFuzzy", 20, false, "[石头]"),
            firewood = HighlightModule.new("Firewood", "pathFuzzy", "item"),
            firewoodnt = NameTagModule.new("Firewood", "pathFuzzy", 20, false, "[木头]"),
        },
    }
}
data["basicdata"]["otherdata"]["musicbox"]["Volume"] = 0.5
data["basicdata"]["otherdata"]["musicbox"]["Looped"] = false
data["basicdata"]["otherdata"]["musicbox"]["Parent"] = SoundService
data["basicdata"]["otherdata"]["testSound"]["Volume"] = 0.5
data["basicdata"]["otherdata"]["testSound"]["Parent"] = SoundService
