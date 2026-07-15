-- ====================================================================
-- CÔTÉ CLIENT : CIBLE OX_TARGET ET MENUS CONTEXTUELS OX_LIB
-- ====================================================================

CreateThread(function()
    exports['ox_target']:addGlobalPlayer({
        {
            name = 'police_check_licenses',
            icon = 'fas fa-id-card',
            label = 'Gérer les permis',
            groups = 'police', 
            distance = 2.0,
            onSelect = function(data)
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                if targetId and targetId > 0 then
                    OpenPoliceLicenseMenu(targetId)
                end
            end
        }
    })
end)

function OpenPoliceLicenseMenu(targetServerId)
    lib.registerContext({
        id = 'police_licenses_main',
        title = 'Gestion des Permis (ID: '..targetServerId..')',
        options = {
            {
                title = '🔍 Vérifier les permis',
                description = 'Consulter les permis en BDD du citoyen',
                onSelect = function()
                    TriggerServerEvent('serveur-police:server:check', targetServerId)
                end
            },
            {
                title = '➕ Attribuer une catégorie',
                description = 'Ajouter un permis et forcer la photo',
                onSelect = function()
                    OpenPoliceAddMenu(targetServerId)
                end
            },
            {
                title = '❌ Saisir / Suspendre',
                description = 'Retirer une catégorie et détruire la carte',
                onSelect = function()
                    OpenPoliceRemoveMenu(targetServerId)
                end
            }
        }
    })
    lib.showContext('police_licenses_main')
end

function OpenPoliceAddMenu(targetServerId)
    lib.registerContext({
        id = 'police_licenses_add',
        title = 'Attribuer un permis',
        menu = 'police_licenses_main',
        options = {
            { title = 'Permis Voiture (B)', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'add', targetServerId, 'driving', 'car') end },
            { title = 'Permis Moto (A)', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'add', targetServerId, 'driving', 'motorcycle') end },
            { title = 'Permis Poids Lourd (C)', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'add', targetServerId, 'driving', 'truck') end },
            { title = 'Port d\'arme', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'add', targetServerId, 'weapon') end },
        }
    })
    lib.showContext('police_licenses_add')
end

function OpenPoliceRemoveMenu(targetServerId)
    lib.registerContext({
        id = 'police_licenses_remove',
        title = 'Saisir un permis',
        menu = 'police_licenses_main',
        options = {
            { title = 'Saisir la Voiture (B)', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'remove', targetServerId, 'driving', 'car') end },
            { title = 'Saisir la Moto (A)', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'remove', targetServerId, 'driving', 'motorcycle') end },
            { title = 'Saisir le Poids Lourd (C)', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'remove', targetServerId, 'driving', 'truck') end },
            { title = 'Saisir le Port d\'arme', onSelect = function() TriggerServerEvent('serveur-police:server:action', 'remove', targetServerId, 'weapon') end },
        }
    })
    lib.showContext('police_licenses_remove')
end