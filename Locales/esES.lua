local ADDON_NAME, ns = ...
local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end
local L = ns.L

L["You can use this weapon (%d/%d)."] = "Puedes usar esta arma (%d/%d)."
L["Can be trained in: %s"] = "Se puede entrenar en: %s"
L["Requires the shaman talent 'Two-Handed Axes and Maces'."] = "Requiere el talento de chamán 'Hachas y mazas de dos manos'."
L["Your class cannot use this type of weapon."] = "Tu clase no puede usar este tipo de arma."

L["Weapon Tooltips"] = "Tooltips de armas"
L["Show usable weapons"] = "Mostrar armas utilizables"
L["Green line when you already have the weapon skill, including your current and maximum skill level."] = "Línea verde cuando ya tienes la habilidad de arma, con tu nivel actual y máximo."
L["Show trainable weapons"] = "Mostrar armas entrenables"
L["Yellow line when your class can learn this weapon type but has not yet, listing the cities with a weapon master that teaches it."] = "Línea amarilla cuando tu clase puede aprender este tipo de arma pero aún no lo domina, con las ciudades cuyo maestro de armas lo enseña."
L["Show unusable weapons"] = "Mostrar armas no utilizables"
L["Red line when your class can never use this weapon type."] = "Línea roja cuando tu clase nunca puede usar este tipo de arma."
