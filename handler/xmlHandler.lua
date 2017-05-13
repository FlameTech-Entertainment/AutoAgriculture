--
-- XML CONFIG
--


function AutoAgriculture:createNewCourseFile(fileName)
    local fileHandler = io.open(fileName, "w");
    if fileHandler == nil then
        print("AutoAgriculture (WARNING): Could not create Course File in savegame Folder!")
        print("AutoAgriculture (WARNING): Please check that the file is not locked or read-only; " .. fileName);
    else
        fileHandler:write(self:getDefaultCourses())
        fileHandler:close()
        fileHandler = nil
    end
end

function AutoAgriculture:loadCourses()
    Glance.notifications = {}
    Glance.columnOrder = {}

    -- Attempt (possibly futile) at somehow making a 'standard folder' for setting-/config-files for mods.
    local folder = getUserProfileAppPath() .. "modsSettings";
    
    --
    local fileName = folder .. "/" .. "Glance_Config.XML";
    local tag = "glanceConfig"

    local xmlFile = nil
    if g_dedicatedServerInfo ~= nil then
        print("## Glance: Seems to be running on a dedicated-server. So default built-in configuration values will be used.");
        xmlFile = loadXMLFileFromMemory(tag, self:getDefaultConfig(), true)
    elseif fileExists(fileName) then
        xmlFile = loadXMLFile(tag, fileName)
    else
        print("## Glance: Trying to create a new default configuration file; " .. fileName);
        createFolder(folder)
        self:createNewConfig(fileName)
        xmlFile = loadXMLFile(tag, fileName)
    end;

    --
    local version = getXMLInt(xmlFile, "glanceConfig#version")
    if xmlFile == nil or version == nil then
        print("## Glance: Looks like an error may have occurred, when Glance tried to load its configuration file.");
        print("## Glance: This could be due to a corrupted XML structure, or otherwise problematic file-handling.");
        print("!! Glance: Please quit the game and fix the XML or delete the file to let Glance create a new one; " .. fileName);
        Glance.failedConfigLoad = g_currentMission.time + 10000;
        return;
    end
    if version ~= Glance.cCfgVersion then
        print("!! Glance: The existing Glance_Config.XML file is of a not supported version '"..tostring(version).."', and will NOT be loaded.")
        Glance.failedConfigLoad = g_currentMission.time + 10000;
        return;
    end

    --
    local i=0
    while true do
        local tag = string.format("glanceConfig.general.colors.color(%d)", i)
        i=i+1
        if not hasXMLProperty(xmlFile, tag.."#name") then
            break
        end
        local colorName = getXMLString(xmlFile, tag.."#name")
        Glance.colors[colorName] = {
            Utils.getVectorFromString(getXMLString(xmlFile, tag.."#rgba"))
        }
        if table.getn(Glance.colors[colorName]) ~= 4 then
            -- Error in color setting!
            Glance.colors[colorName] = nil
            print("!! Glance: Glance_Config.XML has invalid color setting, for color name: "..tostring(colorName));
        end
    end
    --
    local function getColorName(xmlFile, tag, defaultColorName)
        local colorName = getXMLString(xmlFile, tag)
        if colorName ~= nil then
            if Glance.colors[colorName] ~= nil then
                return colorName
            end
            print("!! Glance: Glance_Config.XML has invalid color-name '"..tostring(colorName).."', in: "..tostring(tag));
        end
        return defaultColorName
    end
    --
    local tag = "glanceConfig.general.font"
    Glance.cFontSize        = Utils.getNoNil(getXMLFloat(xmlFile, tag.."#size"), Glance.cFontSize)
    Glance.cFontShadowOffs  = Glance.cFontSize * 0.08
    Glance.cLineSpacing     = Glance.cFontSize * 0.9
    Glance.cFontShadowOffs  = Utils.getNoNil(getXMLFloat(xmlFile, tag.."#shadowOffset"), Glance.cFontShadowOffs)
    Glance.cFontShadowColor = getColorName(xmlFile, tag.."#shadowColor", Glance.cFontShadowColor)
    Glance.cLineSpacing     = Glance.cFontSize + Utils.getNoNil(getXMLFloat(xmlFile, tag.."#rowSpacing"), Glance.cLineSpacing - Glance.cFontSize)
    --
    local tag = "glanceConfig.general.placementInDisplay"
    local posX,posY = Utils.getVectorFromString(getXMLString(xmlFile, tag.."#positionXY"))
    Glance.cStartLineX      = Utils.getNoNil(tonumber(posX), Glance.cStartLineX)
    Glance.cStartLineY      = Utils.getNoNil(tonumber(posY), Glance.cStartLineY)
    --
    local tag = "glanceConfig.general.notification"
    if Glance.minNotifyLevel == nil then
        Glance.minNotifyLevel = Utils.getNoNil(getXMLInt(xmlFile, tag.."#minimumLevel"), 2)
    end
    Glance.updateIntervalMS = Utils.clamp(Utils.getNoNil(getXMLInt(xmlFile, tag.."#updateIntervalMs"), Glance.updateIntervalMS), 500, 60000)
    Glance.ignoreHelpboxVisibility = Utils.getNoNil(getXMLBool(xmlFile, tag.."#ignoreHelpboxVisibility"), Glance.ignoreHelpboxVisibility)
    --
    local tag = "glanceConfig.general.lineColors"
    Glance.lineColorDefault                     = getColorName(xmlFile, tag..".default#color", Glance.lineColorDefault)
    Glance.lineColorVehicleControlledByMe       = getColorName(xmlFile, tag..".vehicleControlledByMe#color", Glance.lineColorVehicleControlledByMe)
    Glance.lineColorVehicleControlledByPlayer   = getColorName(xmlFile, tag..".vehicleControlledByPlayer#color", Glance.lineColorVehicleControlledByPlayer)
    Glance.lineColorVehicleControlledByComputer = getColorName(xmlFile, tag..".vehicleControlledByComputer#color", Glance.lineColorVehicleControlledByComputer)
    --
    Glance.maxNotifyLevel = 0;
    local i=0
    while true do
        local tag = string.format("glanceConfig.notifications.notification(%d)", i)
        i=i+1
        if not hasXMLProperty(xmlFile, tag.."#type") then
            break
        end
        local notifyType = getXMLString(xmlFile, tag.."#type")
        Glance.notifications[notifyType] = {
             enabled        = Utils.getNoNil(getXMLBool(   xmlFile, tag.."#enabled"), false)
            ,notifyType     =                getXMLString( xmlFile, tag.."#type")
            ,level          = Utils.getNoNil(getXMLInt(    xmlFile, tag.."#level"), 0)
            ,aboveThreshold = Utils.getNoNil(getXMLFloat(  xmlFile, tag.."#whenAbove"), getXMLFloat(xmlFile, tag.."#whenAboveThreshold")) -- Still support old-config attributes.
            ,belowThreshold = Utils.getNoNil(getXMLFloat(  xmlFile, tag.."#whenBelow"), getXMLFloat(xmlFile, tag.."#whenBelowThreshold")) -- Still support old-config attributes.
            ,text           =                getXMLString( xmlFile, tag.."#text")
            ,color          =                getColorName( xmlFile, tag.."#color", nil)
        }
        --
        Glance.notifications[notifyType].thresholds = {}
        local j=0
        while true do
            local subTag = ("%s.threshold(%d)"):format(tag, j)
            j=j+1
            if not hasXMLProperty(xmlFile, subTag.."#level") then
                break
            end
            Glance.notifications[notifyType].thresholds[j] = {
                 level          = Utils.getNoNil(getXMLInt(    xmlFile, subTag.."#level"), 0)
                ,aboveThreshold =                getXMLFloat(  xmlFile, subTag.."#whenAbove")
                ,belowThreshold =                getXMLFloat(  xmlFile, subTag.."#whenBelow")
                ,text           =                getXMLString( xmlFile, subTag.."#text")
                ,color          =                getColorName( xmlFile, subTag.."#color", nil)
                ,blinkIcon      =                getXMLBool(   xmlFile, subTag.."#blinkIcon")
            }
            --
            Glance.notifications[notifyType].level = math.max(Glance.notifications[notifyType].level, Glance.notifications[notifyType].thresholds[j].level)
        end
        --
        Glance.maxNotifyLevel = math.max(Glance.maxNotifyLevel, Glance.notifications[notifyType].level)
    end
    --
    Glance.collisionDetection_belowThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "glanceConfig.notifications.collisionDetection#whenBelowThreshold"), Glance.collisionDetection_belowThreshold);

    Glance.nonVehiclesSeparator = Utils.getNoNil(getXMLString(xmlFile, "glanceConfig.nonVehicles#separator"), Glance.nonVehiclesSeparator);
    Glance.nonVehiclesFillLevelFormat = Utils.getNoNil(getXMLString(xmlFile, "glanceConfig.nonVehicles#fillLevelFormat"), Glance.nonVehiclesFillLevelFormat);

    --
    Glance.columnSpacingTxt = Utils.getNoNil(getXMLString(xmlFile, "glanceConfig.vehiclesColumnOrder#columnSpacing"), Glance.columnSpacingTxt);
    Glance.columnSpacing = tonumber(Glance.columnSpacingTxt)
    if Glance.columnSpacing == nil then
        Glance.columnSpacing = Utils.getNoNil(getTextWidth(Glance.cFontSize, Glance.columnSpacingTxt), 0.001)
    end

    local i=0
    while true do
        local tag = string.format("glanceConfig.vehiclesColumnOrder.column(%d)", i)
        i=i+1
        if not hasXMLProperty(xmlFile, tag.."#contains") then
            break
        end
        Glance.columnOrder[i] = {
             enabled      =                        Utils.getNoNil(getXMLBool(  xmlFile, tag.."#enabled"), false)
            ,color        =                                       getColorName(xmlFile, tag.."#color", nil)
            ,text         =                                       getXMLString(xmlFile, tag.."#text")
            ,align        =                        Utils.getNoNil(getXMLString(xmlFile, tag.."#align"), "left")
            ,minWidthText =             Utils.trim(Utils.getNoNil(getXMLString(xmlFile, tag.."#minWidthText"), ""))
            ,maxTextLen   =                              tonumber(getXMLString(xmlFile, tag.."#maxTextLen"))
            ,contains     = Utils.splitString(";", Utils.getNoNil(getXMLString(xmlFile, tag.."#contains"),""))
        }
    end
    --
    delete(xmlFile)

    Glance.failedConfigLoad = nil;
    if g_dedicatedServerInfo == nil then
        print("## Glance: (Re)Loaded settings from: "..fileName)
    end
end