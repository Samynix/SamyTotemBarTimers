SamyTotemBarTimersButtonBase = {}

function SamyTotemBarTimersButtonBase:Create(parentFrame, frameName, templates)
    local instance = {}

    instance.isEnabled = false;
    instance.frame = CreateFrame("Button", frameName, parentFrame, templates)
    instance.frame:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight())

    function instance:SetTexture(spellName)
        if (not SamyTotemBarTimersUtils:StringIsNilOrEmpty(spellName)) then
            instance.frame.icon:SetTexture(select(3, GetSpellInfo(spellName)))
        else
            instance.frame.icon:SetTexture(nil)
        end
    end

    function instance:SetEnabled(isEnabled)
        instance.isEnabled = isEnabled;
    end

    function instance:ClearSpell()
        instance.disableSpellChanged = true
        instance.frame:SetAttribute("type", nil);
        instance.frame:SetAttribute("spell", nil);

        instance.spellName = nil
        instance.elementId = nil
        instance.hasBuff = nil
    end

    function instance:SetSpell(spellName, elementId, isSecure, isDisableSpellChanged)
        instance.disableSpellChanged = isDisableSpellChanged or false

        if (not isSecure and not SamyTotemBarTimersUtils:StringIsNilOrEmpty(spellName)) then
            instance.frame:SetAttribute("type", "spell");
            instance.frame:SetAttribute("spell", spellName);
        end

        instance.spellName = spellName
        instance.elementId = elementId
    end

    function instance:SetHasBuff(hasBuff)
        instance.hasBuff = hasBuff
    end

    function instance:SetPosition(x, y)
        instance.frame:SetPoint("LEFT", parentFrame, "LEFT", x, y);
    end

    function instance:ResetAndHide()

    end

    function instance:SetVisibility(isVisible)
        if (isVisible) then
            instance.frame:Show()
        else
            instance.frame:Hide()
        end
    end

    return instance
end
