local CurrentVersion = "1.0.0"
local GitHubRepo = "Dorinoo/license_linkjobs" 

CreateThread(function()
    Wait(1000) 
    if GetResourceState('bit-licenses') ~= 'started' then
        print("^1====================================================================^7")
        print("^1[license_linkjobs] ERREUR CRITIQUE : 'bit-licenses' n'est pas démarré !^7")
        print("^1Le script ne fonctionnera pas correctement sans cette dépendance.^7")
        print("^1====================================================================^7")
    else
        print("^2[license_linkjobs] Liaison établie avec succès avec 'bit-licenses'.^7")
    end

    local updateUrl = "https://raw.githubusercontent.com/" .. GitHubRepo .. "/main/version.txt"
    
    PerformHttpRequest(updateUrl, function(statusCode, response, headers)
        if statusCode == 200 and response then
            local latestVersion = response:gsub("%s+", "")
            
            if latestVersion ~= CurrentVersion then
                print("^1====================================================================^7")
                print("^1[license_linkjobs] UNE NOUVELLE MISE À JOUR EST DISPONIBLE !^7")
                print("^3Votre version : ^7" .. CurrentVersion)
                print("^2Dernière version : ^7" .. latestVersion)
                print("^3Veuillez télécharger la dernière version sur votre espace Keymaster / Tebex.^7")
                print("^1====================================================================^7")
            else
                print("^2[license_linkjobs] Le script est à jour (v" .. CurrentVersion .. ").^7")
            end
        else
            print("^3[license_linkjobs] Impossible de vérifier les mises à jour en ligne (Code HTTP : " .. tostring(statusCode) .. ").^7")
        end
    end, "GET")
end)

-- ====================================================================
-- CÔTÉ SERVEUR : VÉRIFICATIONS JOB ET EXPORTS INTER-RESSOURCES
-- ====================================================================

RegisterNetEvent('serveur-police:server:check', function(targetServerId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetServerId)

    if xPlayer and xPlayer.job.name == 'police' and targetPlayer then
        TriggerEvent('bit-licenses:server:viewLicenseDirect', targetPlayer.source, 'driving')
    end
end)

RegisterNetEvent('serveur-police:server:action', function(action, targetServerId, licenseType, subCategory)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetServerId)

    if not xPlayer or xPlayer.job.name ~= 'police' or not targetPlayer then return end

    exports.oxmysql:single('SELECT licenses FROM bit_licenses WHERE identifier = ?', { targetPlayer.identifier }, function(result)
        local currentLicenses = {}
        if result and result.licenses then
            currentLicenses = json.decode(result.licenses)
        end

        if action == "add" then
            if licenseType == "driving" then
                if not currentLicenses.driving then
                    currentLicenses.driving = { status = true, type = { car = false, helicopter = false, boat = false, truck = false, plane = false, motorcycle = false } }
                end
                if subCategory then currentLicenses.driving.type[subCategory] = true end
            else
                currentLicenses[licenseType] = true
            end

            exports.oxmysql:update('UPDATE bit_licenses SET licenses = ? WHERE identifier = ?', {
                json.encode(currentLicenses),
                targetPlayer.identifier
            }, function(affectedRows)
                TriggerEvent('bit-licenses:server:givelicenseFromSchool', targetPlayer.source, subCategory or licenseType, false)
                
                xPlayer.showNotification("Vous avez attribué le permis.")
                targetPlayer.showNotification("~g~Un officier vous a accordé une nouvelle catégorie de permis.")
            end)

        elseif action == "remove" then
            if licenseType == "driving" and subCategory then
                if currentLicenses.driving and currentLicenses.driving.type then
                    currentLicenses.driving.type[subCategory] = false
                end
            else
                currentLicenses[licenseType] = false
            end

            exports.oxmysql:update('UPDATE bit_licenses SET licenses = ? WHERE identifier = ?', {
                json.encode(currentLicenses),
                targetPlayer.identifier
            }, function(affectedRows)
                local itemToRemove = licenseType == "driving" and "driver_license" or "license_" .. licenseType
                targetPlayer.removeInventoryItem(itemToRemove, 1)
                
                xPlayer.showNotification("Vous avez saisi le permis du citoyen.")
                targetPlayer.showNotification("~r~Votre permis de conduire a été saisi par la police.")
            end)
        end
    end)
end)