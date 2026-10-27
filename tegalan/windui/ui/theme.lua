--[[ theme.lua — palet warna PINK ROYALE ELEGAN + helper pembuat Instance.
     Karakter: Midnight Velvet Rose, Shimmering Pearl, Radiant Hot Rose, Soft Neon Sakura. ]]
return function(ctx)
	local C = {
		bg        = Color3.fromRGB(15, 9, 20),         -- Deep obsidian velvet (solid & clean)
		panel     = Color3.fromRGB(24, 13, 31),        -- Dark luxury wine panel
		row       = Color3.fromRGB(36, 19, 46),        -- Card container
		rowAlt    = Color3.fromRGB(58, 28, 74),        -- Elevated card / active item
		rowHover  = Color3.fromRGB(72, 35, 92),        -- Hover state card
		stroke    = Color3.fromRGB(255, 95, 175),      -- Radiant rose-pink border
		strokeSub = Color3.fromRGB(130, 68, 140),      -- Clear border outline
		acc       = Color3.fromRGB(255, 55, 145),      -- Hot Radiant Rose (aksen utama)
		acc2      = Color3.fromRGB(255, 135, 205),     -- Soft Neon Sakura (gradient partner)
		accSoft   = Color3.fromRGB(255, 215, 240),     -- Pastel Rose Shimmer (teks aksen super terang)
		glow      = Color3.fromRGB(255, 60, 145),      -- Ambient glow
		txt       = Color3.fromRGB(255, 255, 255),     -- Pure White (teks utama ultra-tajam & kontras tinggi)
		sub       = Color3.fromRGB(235, 205, 235),     -- Light Soft Rose-Lilac (deskripsi & label sekunder terbaca jelas!)
		green     = Color3.fromRGB(110, 245, 185),     -- Luminous Mint-Emerald
		red       = Color3.fromRGB(255, 75, 120),      -- Passion Crimson Rose
	}

	local F = {
		title = Enum.Font.FredokaOne,       -- Judul / Header / Branding (Modern & Segar, beda total dari Gotham)
		bold  = Enum.Font.MontserratBold,   -- Subheader / Tombol / Label Tebal (Tajam & Elegan)
		semi  = Enum.Font.MontserratMedium, -- Dropdown item / Value pill
		reg   = Enum.Font.Ubuntu,           -- Deskripsi & isi teks (Sangat nyaman dibaca)
		code  = Enum.Font.Code,             -- Console logs
	}

	local function mk(cls, props, parent)
		local o = Instance.new(cls)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end

	local function corner(o, r)
		return mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o)
	end

	local function stroke(o, col, thick, trans)
		return mk("UIStroke", {
			Color = col or C.strokeSub,
			Thickness = thick or 1.2,
			Transparency = trans or 0.35,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, o)
	end

	local function pad(o, l, r, t, b)
		return mk("UIPadding", {
			PaddingLeft = UDim.new(0, l),
			PaddingRight = UDim.new(0, r),
			PaddingTop = UDim.new(0, t),
			PaddingBottom = UDim.new(0, b),
		}, o)
	end

	local function grad(o, rot, col1, col2)
		return mk("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, col1 or C.acc),
				ColorSequenceKeypoint.new(1, col2 or C.acc2),
			}),
			Rotation = rot or 90,
		}, o)
	end

	ctx.C      = C
	ctx.F      = F
	ctx.mk     = mk
	ctx.corner = corner
	ctx.stroke = stroke
	ctx.pad    = pad
	ctx.grad   = grad
end
