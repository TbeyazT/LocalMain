local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player.PlayerGui

local MainUI = PlayerGui:WaitForChild("SoccerUI", 100)
local Storage = ReplicatedStorage:WaitForChild("Storage")

local CameraBlur = Instance.new("BlurEffect")
CameraBlur.Parent = Camera
CameraBlur.Size = 0

local TowerViewportCFrame = CFrame.new(0, 0, -4.5, -1, 0, -1.50995803e-07, 0, 1, 0, 1.50995803e-07, 0, -1) 
local TowerOpenninCFrame = CFrame.new(-273.187622, 22.8321095, -120.865646, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local CameraStartingCFrame = CFrame.new(-273.064789, 21.9959793, -226.306824, -1, 0, 0, 0, 1, 9.09494702e-13, 0, -9.09494702e-13, -1)
local CameraEndCFrame = CFrame.new(-273.065002, 21.9960003, -141.214005, -1, 7.95105521e-20, -8.74227766e-08, 0, 1, 9.09494702e-13, 8.74227766e-08, 9.09494702e-13, -1)
local TowerScale = 1.736
local HatchingAnimationSpeed = 0.7

local UIModule = require(Storage.Modules.UIModule)
local GoodSignal = require(Storage.Modules.GoodSignal)
local EasyVisuals = require(Storage.Modules.EasyVisuals)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient",100))

local OnTowerChanged = GoodSignal.new()
local OnTowerAdded = GoodSignal.new()
local OnSelectedChanged = GoodSignal.new()

_G.OnTowerChanged = OnTowerChanged
_G.OnTowerAdded = OnTowerAdded
_G.OnSelectChanged = OnSelectedChanged

local VisibleComponent = UIModule:GetComponent("Visible")
local AnimationComponent = UIModule:GetComponent("Animation")
local PopupComponent = UIModule:GetComponent("Popup")
local BillboardComponent = UIModule:GetComponent("Billboard")
local FlagDatas = require(Storage.Modules.FlagData)

repeat
	task.wait(0.5)
until game:IsLoaded()

repeat
	task.wait(0.5)
until Player:FindFirstChild("DataLoaded") and Player.DataLoaded.Value

task.spawn(function()
	UIModule:GetComponent("Settings"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("Elevator"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("Summon"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("Music"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("DailyRewards"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("TimeRewards"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("Coins"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("TowerPets"):Init()
end)
task.spawn(function()
	UIModule:GetComponent("Trade"):Init()
end)

local ActiveFrame = nil
local SelectedTower = nil
local SelectedTowerKey = nil
local DeletingTowers = false
local FrameMetas = {}
local TowersToDelete = {}

local function setBlur(size, duration)
	TweenService:Create(CameraBlur, TweenInfo.new(duration), {Size = size}):Play()
end

local function getRandomChild(Table)
	if typeof(Table) == "table" then
		return Table[math.random(1, #Table)]
	elseif typeof(Table) == "Instance" then
		return Table:GetChildren()[math.random(1, #Table:GetChildren())]
	end
end

local function SetPlaylistEnabled(value)
	for _,Sound in pairs(SoundService:WaitForChild("Playlist"):GetChildren()) do
		if Sound:IsA("Sound") then
			TweenService:Create(Sound,TweenInfo.new(1),{
				Volume = value and 0.5 or not value and 0
			}):Play()
		end
	end
end

local function loadAnimation(Animator,ID)
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://"..ID
	local LoadedAnimation = Animator:LoadAnimation(animation)
	animation:Destroy()
	return LoadedAnimation
end

Cmdr:SetActivationKeys({Enum.KeyCode.F2})

for _,AnimatePart in pairs(CollectionService:GetTagged("AnimatedText")) do
	local Sign = AnimatePart:FindFirstChild("SurfaceGui").SIGN
	task.spawn(function()
		EasyVisuals.new(Sign, "Ghost", 1)
	end)
end

Storage.Events.Notification.OnClientEvent:Connect(function(...)
	PopupComponent:Spawn(...)
end)

for _, SideButton in pairs(CollectionService:GetTagged("SideButtons")) do
	if SideButton:IsA("GuiButton") then
		local animClass = AnimationComponent.new(SideButton)
		animClass:Init(nil, nil)

		task.spawn(function()
			local visClass = VisibleComponent.new(SideButton)
			task.wait(0.1)
			visClass:Visible(false)
			task.wait(0.1)
			visClass:Visible(true)
			task.wait(0.1)
			visClass:destroy()
		end)

		local type = SideButton:FindFirstChild("Type")
		if type and type.Value then
			type = type.Value
		end

		if type then
			local newVisClass = VisibleComponent.new(type)
			FrameMetas[type] = newVisClass

			if type:FindFirstChild("XButton") then
				local newAnimClass = AnimationComponent.new(type.XButton)
				newAnimClass:Init(nil, function()
					setBlur(0, 0.3)
					newVisClass:Visible(false)
					if ActiveFrame == type then
						ActiveFrame = nil
					end
				end)
			end

			animClass:Init(nil, function()
				if ActiveFrame == type then
					local currentVisClass = FrameMetas[ActiveFrame]
					if currentVisClass then
						setBlur(0, 0.3)
						currentVisClass:Visible(false)
					end
					ActiveFrame = nil
				else
					if not ActiveFrame then
						ActiveFrame = type
						if ActiveFrame then
							setBlur(24, 0.3)
							local newVisClass = FrameMetas[ActiveFrame]
							newVisClass:Visible(true)
						end
					end
				end
			end)
		else
			warn(SideButton:GetFullName().." No Type Found")
		end
	end
end

for _,FakeBillboard in pairs(CollectionService:GetTagged("Billboards")) do
	BillboardComponent.new(FakeBillboard)
		:StartBillboard()
end

local SummonVisComp = VisibleComponent.new(MainUI.SummonFrame.MainFrame)
SummonVisComp:Visible(false)

local IsVisible = false
local LastTick = tick()

local closeClass = AnimationComponent.new(MainUI.SummonFrame.MainFrame.XButton)

closeClass:Init(nil, function()
	local humanoid:Humanoid = Player.Character:FindFirstChild("Humanoid")
	humanoid.WalkSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed
	humanoid.JumpPower = game:GetService("StarterPlayer").CharacterJumpPower
	humanoid.JumpHeight = game:GetService("StarterPlayer").CharacterJumpHeight
	local Tween1 = TweenService:Create(MainUI.BlackFrame, TweenInfo.new(0.5), {
		BackgroundTransparency = 0
	})
	Tween1:Play()
	Tween1.Completed:Wait()
	local Tween = TweenService:Create(MainUI.BlackFrame, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	})
	Tween:Play()
	IsVisible = false
	MainUI.SideButtons.Visible = true
	MainUI.Buttons.Visible = true
	MainUI.TowerButtons.Visible = true
	LastTick = tick()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = Player.Character.Humanoid
	setBlur(0, 0.6)
	task.spawn(function()
		SummonVisComp:Visible(false)
	end)
end)

local function ShowSummonUI()
	if not IsVisible then
		local humanoid:Humanoid = Player.Character:FindFirstChild("Humanoid")
		Player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(14.1964417, 12.2511177, -420.547241, 0.622004986, 0, 0.783013463, 1.84111177e-05, 1, -1.04487181e-05, -0.783013403, 1.76783105e-05, 0.622005105)
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		IsVisible = true
		local Tween1 = TweenService:Create(MainUI.BlackFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = 0
		})
		Tween1:Play()
		Tween1.Completed:Wait()
		local Tween = TweenService:Create(MainUI.BlackFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		})
		Tween:Play()
		MainUI.SideButtons.Visible = false
		MainUI.Buttons.Visible = false
		MainUI.TowerButtons.Visible = false
		if ActiveFrame then
			ActiveFrame.Visible = false
		end
		for _, visClass in pairs(FrameMetas) do
			task.spawn(function()
				visClass:Visible(false)
			end)
		end
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = workspace.hmm.CFrame
		Camera.CameraSubject = workspace.hmm
		setBlur(24, 0.6)
		task.spawn(function()
			SummonVisComp:Visible(true)
		end)
	end
end

workspace:WaitForChild("SummonPart"):WaitForChild("Hitbox").Touched:Connect(function(hit)
	if Players:GetPlayerFromCharacter(hit.Parent) and hit.Parent.PrimaryPart == Player.Character.PrimaryPart then
		if LastTick and tick() - LastTick < 1 then
			return
		end
		ShowSummonUI()
	end
end)

workspace:WaitForChild("AfkArea"):WaitForChild("Hitbox").Touched:Connect(function(hit)
	if Players:GetPlayerFromCharacter(hit.Parent) and hit.Parent.PrimaryPart == Player.Character.PrimaryPart then
		local attemptIndex = 0
		local success, result 
		repeat
			success, result = pcall(function()
				return TeleportService:Teleport(18815146970,Player)
			end)
			attemptIndex += 1
			if not success then
				task.wait(2)
			end
		until success or attemptIndex == 10
	end
end)

local function getPlayerData()
	return Storage.Events.GetState:InvokeServer()
end

local function getRarityValue(rarity)
	local rarityValues = {
		["Common"] = 1,
		["Uncommon"] = 2,
		["Rare"] = 3,
		["Legendary"] = 4,
		["Mythical"] = 5
	}
	return rarityValues[rarity] or 0
end

local function updateTowers()
	local PlayerData = getPlayerData()
	local TowerData = PlayerData.EquippedTowers

	for _, TowerButton:ImageButton in pairs(MainUI.TowerButtons:GetChildren()) do
		if TowerButton:IsA("GuiButton") then
			local TowerNum = tonumber(TowerButton.Number.Value)
			local animClass = AnimationComponent.new(TowerButton)
			animClass:Init(nil, nil)
			if TowerNum and TowerData[TowerNum] then
				local Tower = TowerData[TowerNum]
				TowerButton.TowerImage.Image = "rbxassetid://"..Tower.ImageId
				TowerButton.Amount2.Text = "$"..Tower.Price
			else
				TowerButton.TowerImage.Image = ""
				TowerButton.Amount2.Text = ""
			end
		end
	end
end

local function updateInventory()
	local PlayerData = getPlayerData()
	local TowerTable = PlayerData.Towers
	local TradeContainer = MainUI.InventoryFrame.MainFrame.TradeContainer

	table.sort(TowerTable, function(a, b)
		return getRarityValue(a.Rarity) > getRarityValue(b.Rarity)
	end)

	local towerCount = {}

	for _, TowerDataTable in pairs(TowerTable) do
		if not towerCount[TowerDataTable.Name] then
			towerCount[TowerDataTable.Name] = {data = TowerDataTable, count = 0}
		end
		towerCount[TowerDataTable.Name].count = towerCount[TowerDataTable.Name].count + 1
	end

	for key, towerInfo in pairs(towerCount) do
		local TowerDataTable = towerInfo.data
		local count = towerInfo.count

		if not TradeContainer:FindFirstChild(TowerDataTable.Name) then
			local Template = TradeContainer:FindFirstChild(TowerDataTable.Rarity)
			if Template then
				local CloneTemplate = Template:Clone()
				CloneTemplate.Template:Destroy()
				CloneTemplate.TowerImage.Image = "rbxassetid://"..TowerDataTable.ImageId
				CloneTemplate.TextLabel.Text = TowerDataTable.Name
				if count > 1 then
					CloneTemplate.NumOfTower.Visible = true
					CloneTemplate.NumOfTower.Text = tostring(count).."X"
				end
				CloneTemplate.Visible = true
				CloneTemplate.Name = TowerDataTable.Name
				CloneTemplate.Parent = TradeContainer
				warn(CloneTemplate.Parent)
				local animClass = AnimationComponent.new(CloneTemplate)

				for _,TowerTable in pairs(PlayerData.EquippedTowers) do
					if TowerTable.Name == TowerDataTable.Name then
						CloneTemplate.Checkmark.Visible = true
					end
				end

				animClass:Init(nil, function()
					if not DeletingTowers then
						SelectedTower = TowerDataTable.Name
						SelectedTowerKey = TowerDataTable.Key
						OnSelectedChanged:Fire()
					else
						if not table.find(TowersToDelete,TowerDataTable.Key) then
							table.insert(TowersToDelete,TowerDataTable.Key)
							CloneTemplate.XButton.Visible = true
						else
							table.remove(TowersToDelete,table.find(TowersToDelete,TowerDataTable.Key))
							CloneTemplate.XButton.Visible = false
						end
					end
				end)

				CloneTemplate.Destroying:Connect(function()
					animClass:destroy()
				end)
			end
		else
			local TowerButton = TradeContainer:FindFirstChild(TowerDataTable.Name)
			if TowerButton then
				for _,TowerTable in pairs(PlayerData.Towers) do
					if TowerTable.Name == TowerDataTable.Name then
						TowerButton.Visible = true
						break
					end
				end
				if count > 1 then
					TowerButton.NumOfTower.Visible = true
					TowerButton.NumOfTower.Text = tostring(count).."X"
				end
				TowerButton.Checkmark.Visible = false
				for _,TowerTable in pairs(PlayerData.EquippedTowers) do
					if TowerTable.Name == TowerDataTable.Name then
						TowerButton.Checkmark.Visible = true
						break
					end
				end
			end
		end
	end

	for _,Button in pairs(TradeContainer:GetChildren()) do
		if getRarityValue(Button.Name) == 0 and Button:IsA("GuiButton") and not Button:FindFirstChild("Template") then
			local found = false
			for i,towerTable in pairs(TowerTable) do
				if towerTable.Name == Button.Name then
					found = true
				end
			end
			if found == false then
				Button:Destroy()
			end
		end
	end
end

local SelectedFrame = MainUI.InventoryFrame.MainFrame.CharachterShower
local SearchBar:TextBox = SelectedFrame.Parent.SearchBar.TextBox
local RotateConnection

local function updateSelected()
	local TowerConfig 
	if SelectedTower then
		TowerConfig = Storage.Towers:FindFirstChild(SelectedTower)
	end
	if TowerConfig then
		SelectedFrame.Title.Text = TowerConfig.Name
		SelectedFrame.Grade.Text = TowerConfig.Rarity.Value

		local PlayerData = getPlayerData()
		local TowerTable = PlayerData.EquippedTowers
		local FoundIt = false
		for _, Tower in pairs(TowerTable) do
			if Tower.Name == SelectedTower then
				FoundIt = true
				break
			end
		end
		
		local Model = SelectedFrame.TowerModel:FindFirstChildWhichIsA("Model")
		if Model then
			if RotateConnection then
				RotateConnection:Disconnect()
			end
			Model:Destroy()
		end
		updateTowers()
		if not FoundIt then
			local CloneModel = TowerConfig:FindFirstChildWhichIsA("Model")
			if CloneModel then
				CloneModel = CloneModel:Clone()
				CloneModel.Parent = SelectedFrame.TowerModel
				CloneModel.PrimaryPart = CloneModel.HumanoidRootPart
				CloneModel.HumanoidRootPart.Anchored = true
				CloneModel:PivotTo(TowerViewportCFrame)
				for _,Thing in pairs(CloneModel:GetChildren()) do
					if Thing:IsA("BasePart") then
						Thing.Anchored = false
					end
				end
				RotateConnection = RunService.RenderStepped:Connect(function()
					local hrp:BasePart = CloneModel:FindFirstChild("HumanoidRootPart")
					if hrp then
						CloneModel:PivotTo(CloneModel.PrimaryPart.CFrame*CFrame.Angles(0,math.rad(1),0))
					end
				end)
				local Animation = CloneModel:FindFirstChildWhichIsA("Animation")
				if Animation then
					local Humanoid = CloneModel:FindFirstChildOfClass("Humanoid")
					if Humanoid then						
						local Animator = Humanoid
						local Track = Animator:LoadAnimation(Animation)
						Track:Play()
					else
						warn("No Humanoid found in the model to play the animation")
					end
				else
					warn("No Animation found in the model")
				end
			end
			SelectedFrame.EquipButton.Label.Text = "Equip"
			SelectedFrame.EquipButton.Image = "rbxassetid://18632891142"
		else
			local CloneModel = TowerConfig:FindFirstChildWhichIsA("Model")
			if CloneModel then
				CloneModel = CloneModel:Clone()
				CloneModel.Parent = SelectedFrame.TowerModel
				CloneModel.PrimaryPart = CloneModel.HumanoidRootPart
				CloneModel.HumanoidRootPart.Anchored = true
				CloneModel:PivotTo(TowerViewportCFrame)
				for _,Thing in pairs(CloneModel:GetChildren()) do
					if Thing:IsA("BasePart") then
						Thing.Anchored = false
					end
				end
				RotateConnection = RunService.RenderStepped:Connect(function()
					local hrp:BasePart = CloneModel:FindFirstChild("HumanoidRootPart")
					if hrp then
						CloneModel:PivotTo(CloneModel.PrimaryPart.CFrame*CFrame.Angles(0,math.rad(1),0))
					end
				end)
				local Animation = CloneModel:FindFirstChildWhichIsA("Animation")
				if Animation then
					local Humanoid = CloneModel:FindFirstChildOfClass("Humanoid")
					if Humanoid then						
						local Animator = Humanoid
						local Track = Animator:LoadAnimation(Animation)
						Track:Play()
					else
						warn("No Humanoid found in the model to play the animation")
					end
				else
					warn("No Animation found in the model")
				end
			end
			SelectedFrame.EquipButton.Label.Text = "Unequip"
			SelectedFrame.EquipButton.Image = "rbxassetid://18611141536"
		end
	end
end

local function SearchInventory(Text)
	local PlayerData = getPlayerData()
	local TowerTable = PlayerData.Towers
	local TradeContainer = MainUI.InventoryFrame.MainFrame.TradeContainer

	for _, TowerButton in pairs(TradeContainer:GetChildren()) do
		if TowerButton:IsA("GuiButton") and not TowerButton:FindFirstChild("Template") then
			if string.find(string.lower(TowerButton.Name), string.lower(Text)) then
				TowerButton.Visible = true
			else
				TowerButton.Visible = false
			end
		end
	end
end

local CameraConnection:RBXScriptConnection

local function EditParticles(Parent,Value)
	for _, Particle in pairs(Parent:GetDescendants()) do
		if Particle:IsA("ParticleEmitter") then
			Particle.Enabled = Value
		end
	end
end

local function PlayRevealEffect()
	getRandomChild(script.RevealEffects):Play()
end

local OldDoor1CFrame = workspace.OpenningAnimation.Doors:WaitForChild("Door1").CFrame
local OldDoor2CFrame = workspace.OpenningAnimation.Doors:WaitForChild("Door2").CFrame

local function AnimateTowerBuying(towerNames)
	if type(towerNames) == "string" then
		local towerName = towerNames
		script.PlayerRevealEffect:Play()
		SetPlaylistEnabled(false)
		setBlur(0, 0)
		PlayRevealEffect()
		local humanoid:Humanoid = Player.Character:FindFirstChild("Humanoid")
		local CameraModel = Storage.CameraRig:Clone()
		local TowerModel = Storage.Towers:FindFirstChild(towerName):FindFirstChildWhichIsA("Model")
		TowerModel.PrimaryPart = TowerModel.HumanoidRootPart
		CameraModel.Parent = workspace
		CameraModel:PivotTo(CameraStartingCFrame)
		local TextPart = workspace.OpenningAnimation.TextPart
		local ImagePart = workspace.OpenningAnimation.FlagImagePart
		local FireWorkEffects = workspace.OpenningAnimation.FireWorkEffects
		local stopped = false

		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = Player.Character:FindFirstChild("Humanoid")

		CameraConnection = RunService.RenderStepped:Connect(function()
			if not stopped then
				Camera.CFrame = CameraModel.CamPart.CFrame
			else
				Camera.CFrame = CameraEndCFrame
			end
		end)

		local Tweens = {}
		local TowerClone
		local UserConnection
		local destroying = false

		workspace.OpenningAnimation.Doors:WaitForChild("Door1").CFrame = OldDoor1CFrame
		workspace.OpenningAnimation.Doors:WaitForChild("Door2").CFrame = OldDoor2CFrame

		local OpenDoor1CFrame = OldDoor1CFrame * CFrame.new(Vector3.new(0, 0, -12.50))
		local OpenDoor2CFrame = OldDoor2CFrame * CFrame.new(Vector3.new(0, 0, 12.50))

		Lighting.ColorCorrection.TintColor = Color3.fromRGB(0, 0, 0)

		local Tween = TweenService:Create(Lighting.ColorCorrection, TweenInfo.new(2.5), {
			TintColor = Color3.fromRGB(255, 255, 255)
		})
		Tween:Play()
		table.insert(Tweens, Tween)

		MainUI.SideButtons.Visible = false
		MainUI.Buttons.Visible = false
		MainUI.TowerButtons.Visible = false
		MainUI.CoinFrame.Visible = false
		MainUI.SummonFrame.MainFrame.Visible = false
		IsVisible = false
		if ActiveFrame then
			ActiveFrame.Visible = false
		end
		for _, visClass in pairs(FrameMetas) do
			task.spawn(function()
				visClass:Visible(false)
			end)
		end

		local Animation = loadAnimation(CameraModel.AnimationController, "18787929303")
		Animation:Play()
		Animation:AdjustSpeed(HatchingAnimationSpeed)

		local function destroy()
			UserConnection:Disconnect()
			for _,Tweenn:Tween in pairs(Tweens) do
				Tweenn:Cancel()
				Tween:Destroy()
			end
			SetPlaylistEnabled(true)
			workspace.OpenningAnimation.Doors:WaitForChild("Door1").CFrame = OldDoor1CFrame
			workspace.OpenningAnimation.Doors:WaitForChild("Door2").CFrame = OldDoor2CFrame
			MainUI.SideButtons.Visible = true
			MainUI.Buttons.Visible = true
			MainUI.TowerButtons.Visible = true
			MainUI.CoinFrame.Visible = true
			ShowSummonUI()
			for _, TextLabel: TextLabel in pairs(MainUI.Rarity:GetChildren()) do
				TextLabel.Visible = false
			end
			Lighting.ColorCorrection.TintColor = Color3.fromRGB(0, 0, 0)

			local Tween = TweenService:Create(Lighting.ColorCorrection, TweenInfo.new(2.5), {
				TintColor = Color3.fromRGB(255, 255, 255)
			})
			Tween:Play()
			for _, Sound in pairs(script:GetDescendants()) do
				if Sound:IsA("Sound") and Sound.Playing then
					Sound:Stop()
				end
			end
			if CameraConnection then
				CameraConnection:Disconnect()
			end
			CameraModel:Destroy()
			if TowerClone then
				TowerClone:Destroy()
			end
			EditParticles(FireWorkEffects, false)
			ImagePart.Decal.Transparency = 1
			TextPart.SurfaceGui.SIGN.TextTransparency = 1
		end

		Animation:GetMarkerReachedSignal("FlagOpen"):Connect(function()
			task.spawn(function()
				ImagePart.Decal.Texture = FlagDatas[Storage.Towers[towerName].CountryCode.Value].Decal
				TweenService:Create(ImagePart.Decal, TweenInfo.new(0.3), {
					Transparency = 0
				}):Play()
				task.wait(0.8)
				TweenService:Create(ImagePart.Decal, TweenInfo.new(0.3), {
					Transparency = 1
				}):Play()
			end)
		end)

		Animation:GetMarkerReachedSignal("TeamFlagOpen"):Connect(function()
			task.spawn(function()
				TweenService:Create(workspace.OpenningAnimation.TeamFlag.Decal, TweenInfo.new(0.3), {
					Transparency = 0
				}):Play()
				task.wait(0.8)
				TweenService:Create(workspace.OpenningAnimation.TeamFlag.Decal, TweenInfo.new(0.3), {
					Transparency = 1
				}):Play()
			end)
		end)

		Animation:GetMarkerReachedSignal("TextOpen"):Connect(function()
			task.spawn(function()
				TweenService:Create(TextPart.SurfaceGui.SIGN, TweenInfo.new(0.3), {
					TextTransparency = 0
				}):Play()
				task.wait(0.8)
				TweenService:Create(TextPart.SurfaceGui.SIGN, TweenInfo.new(0.3), {
					TextTransparency = 1
				}):Play()
			end)
		end)

		local d1

		Animation:GetMarkerReachedSignal("PlayerOpen"):Connect(function()
			UserConnection = UserInputService.InputBegan:Connect(function(input, gpe)
				if gpe then
					return
				end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					destroy()
				end
			end)
			MainUI.Rarity.TName.Text = towerName
			MainUI.Rarity.Rarity.Text = Storage.Towers:FindFirstChild(towerName).Rarity.Value
			for _, TextLabel: TextLabel in pairs(MainUI.Rarity:GetChildren()) do
				TextLabel.Visible = true
			end
			task.wait(0.5)
			task.spawn(function()
				MainUI.Rarity.Visible = true
			end)
			local Tween = TweenService:Create(workspace.OpenningAnimation.Doors:WaitForChild("Door1"), TweenInfo.new(2), {
				CFrame = OpenDoor1CFrame
			})
			Tween:Play()
			table.insert(Tweens, Tween)
			local Tween = TweenService:Create(workspace.OpenningAnimation.Doors:WaitForChild("Door2"), TweenInfo.new(2), {
				CFrame = OpenDoor2CFrame
			})
			Tween:Play()
			table.insert(Tweens, Tween)
			TowerClone = TowerModel:Clone()
			TowerClone.Parent = workspace
			TowerClone.PrimaryPart = TowerClone:FindFirstChild("HumanoidRootPart")
			TowerClone:PivotTo(TowerOpenninCFrame * CFrame.new(0, 0, 35))
			TweenService:Create(TowerClone.PrimaryPart, TweenInfo.new(2), {
				CFrame = TowerOpenninCFrame
			}):Play()
			TowerClone:ScaleTo(TowerScale)
			EditParticles(FireWorkEffects, true)
			TowerClone.HumanoidRootPart.Anchored = true
			local Animation = TowerModel:FindFirstChildWhichIsA("Animation")
			if Animation then
				local LoadedAnimation = TowerClone:FindFirstChild("Humanoid"):LoadAnimation(Animation)

				LoadedAnimation:Play()
			end
		end)

		Animation.Stopped:Connect(function()
			stopped = true
		end)
	elseif type(towerNames) == "table" then
		script.PlayerRevealEffect:Play()
		SetPlaylistEnabled(false)
		setBlur(0, 0)
		PlayRevealEffect()

		table.sort(towerNames, function(a, b)
			return getRarityValue(Storage.Towers[a].Rarity.Value) > getRarityValue(Storage.Towers[b].Rarity.Value)
		end)

		local bestTower = towerNames[1]
		local otherTowers = {unpack(towerNames, 2)}

		local CameraModel = Storage.CameraRig:Clone()
		local TowerModel = Storage.Towers:FindFirstChild(bestTower):FindFirstChildWhichIsA("Model")
		TowerModel.PrimaryPart = TowerModel.HumanoidRootPart
		CameraModel.Parent = workspace
		CameraModel:PivotTo(CameraStartingCFrame)
		local TextPart = workspace.OpenningAnimation.TextPart
		local ImagePart = workspace.OpenningAnimation.FlagImagePart
		local FireWorkEffects = workspace.OpenningAnimation.FireWorkEffects
		local stopped = false
		local destroying = false

		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = Player.Character:FindFirstChild("Humanoid")

		local CameraConnection = RunService.RenderStepped:Connect(function()
			if not stopped then
				Camera.CFrame = CameraModel.CamPart.CFrame
			else
				Camera.CFrame = CameraEndCFrame
			end
		end)

		local Tweens = {}
		local TowerClone
		local UserConnection

		workspace.OpenningAnimation.Doors:WaitForChild("Door1").CFrame = OldDoor1CFrame
		workspace.OpenningAnimation.Doors:WaitForChild("Door2").CFrame = OldDoor2CFrame

		local OpenDoor1CFrame = OldDoor1CFrame * CFrame.new(Vector3.new(0, 0, -12.50))
		local OpenDoor2CFrame = OldDoor2CFrame * CFrame.new(Vector3.new(0, 0, 12.50))

		Lighting.ColorCorrection.TintColor = Color3.fromRGB(0, 0, 0)

		local Tween = TweenService:Create(Lighting.ColorCorrection, TweenInfo.new(2.5), {
			TintColor = Color3.fromRGB(255, 255, 255)
		})
		Tween:Play()
		table.insert(Tweens, Tween)

		MainUI.SideButtons.Visible = false
		MainUI.Buttons.Visible = false
		MainUI.TowerButtons.Visible = false
		MainUI.CoinFrame.Visible = false
		MainUI.SummonFrame.MainFrame.Visible = false
		IsVisible = false
		if ActiveFrame then
			ActiveFrame.Visible = false
		end
		for _, visClass in pairs(FrameMetas) do
			task.spawn(function()
				visClass:Visible(false)
			end)
		end

		local Animation = loadAnimation(CameraModel.AnimationController, "18787929303")
		Animation:Play()
		Animation:AdjustSpeed(HatchingAnimationSpeed)
		
		local towersss = {}

		local function destroy()
			destroying = true
			for _,tower in pairs(towersss) do
				tower:Destroy()
			end
			UserConnection:Disconnect()
			for _, Tween in pairs(Tweens) do
				Tween:Cancel()
				Tween:Destroy()
			end
			SetPlaylistEnabled(true)
			workspace.OpenningAnimation.Doors:WaitForChild("Door1").CFrame = OldDoor1CFrame
			workspace.OpenningAnimation.Doors:WaitForChild("Door2").CFrame = OldDoor2CFrame
			MainUI.SideButtons.Visible = true
			MainUI.Buttons.Visible = true
			MainUI.TowerButtons.Visible = true
			MainUI.CoinFrame.Visible = true
			ShowSummonUI()
			for _, TextLabel: TextLabel in pairs(MainUI.Rarity:GetChildren()) do
				TextLabel.Visible = false
			end
			Lighting.ColorCorrection.TintColor = Color3.fromRGB(0, 0, 0)

			local Tween = TweenService:Create(Lighting.ColorCorrection, TweenInfo.new(2.5), {
				TintColor = Color3.fromRGB(255, 255, 255)
			})
			Tween:Play()
			for _, Sound in pairs(script:GetDescendants()) do
				if Sound:IsA("Sound") and Sound.Playing then
					Sound:Stop()
				end
			end
			if CameraConnection then
				CameraConnection:Disconnect()
			end
			CameraModel:Destroy()
			if TowerClone then
				TowerClone:Destroy()
			end
			EditParticles(FireWorkEffects, false)
			ImagePart.Decal.Transparency = 1
			TextPart.SurfaceGui.SIGN.TextTransparency = 1
		end

		Animation:GetMarkerReachedSignal("FlagOpen"):Connect(function()
			task.spawn(function()
				ImagePart.Decal.Texture = FlagDatas[Storage.Towers[bestTower].CountryCode.Value].Decal
				TweenService:Create(ImagePart.Decal, TweenInfo.new(0.3), {
					Transparency = 0
				}):Play()
				task.wait(0.8)
				TweenService:Create(ImagePart.Decal, TweenInfo.new(0.3), {
					Transparency = 1
				}):Play()
			end)
		end)

		Animation:GetMarkerReachedSignal("TeamFlagOpen"):Connect(function()
			task.spawn(function()
				TweenService:Create(workspace.OpenningAnimation.TeamFlag.Decal, TweenInfo.new(0.3), {
					Transparency = 0
				}):Play()
				task.wait(0.8)
				TweenService:Create(workspace.OpenningAnimation.TeamFlag.Decal, TweenInfo.new(0.3), {
					Transparency = 1
				}):Play()
			end)
		end)

		Animation:GetMarkerReachedSignal("TextOpen"):Connect(function()
			task.spawn(function()
				TweenService:Create(TextPart.SurfaceGui.SIGN, TweenInfo.new(0.3), {
					TextTransparency = 0
				}):Play()
				task.wait(0.8)
				TweenService:Create(TextPart.SurfaceGui.SIGN, TweenInfo.new(0.3), {
					TextTransparency = 1
				}):Play()
			end)
		end)

		Animation:GetMarkerReachedSignal("PlayerOpen"):Connect(function()
			UserConnection = UserInputService.InputBegan:Connect(function(input, gpe)
				if gpe then
					return
				end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					destroy()
				end
			end)
			if destroying == true then return end
			MainUI.Rarity.TName.Text = bestTower
			MainUI.Rarity.Rarity.Text = Storage.Towers:FindFirstChild(bestTower).Rarity.Value
			for _, TextLabel: TextLabel in pairs(MainUI.Rarity:GetChildren()) do
				TextLabel.Visible = true
			end
			task.wait(0.5)
			task.spawn(function()
				MainUI.Rarity.Visible = true
			end)
			local Tween = TweenService:Create(workspace.OpenningAnimation.Doors:WaitForChild("Door1"), TweenInfo.new(2), {
				CFrame = OpenDoor1CFrame
			})
			Tween:Play()
			table.insert(Tweens, Tween)
			local Tween = TweenService:Create(workspace.OpenningAnimation.Doors:WaitForChild("Door2"), TweenInfo.new(2), {
				CFrame = OpenDoor2CFrame
			})
			Tween:Play()
			table.insert(Tweens, Tween)
			TowerClone = TowerModel:Clone()
			table.insert(towersss,TowerClone)
			TowerClone.Parent = workspace
			TowerClone.PrimaryPart = TowerClone:FindFirstChild("HumanoidRootPart")
			TowerClone:PivotTo(TowerOpenninCFrame * CFrame.new(0, 0, 35))
			TweenService:Create(TowerClone.PrimaryPart, TweenInfo.new(2), {
				CFrame = TowerOpenninCFrame
			}):Play()
			TowerClone:ScaleTo(TowerScale)
			EditParticles(FireWorkEffects, true)
			TowerClone.HumanoidRootPart.Anchored = true
			local Animation = TowerModel:FindFirstChildWhichIsA("Animation")
			if Animation then
				local LoadedAnimation = TowerClone:FindFirstChild("Humanoid"):LoadAnimation(Animation)
				LoadedAnimation:Play()
			end
			if destroying == true then return end
			task.wait(2.5)
			if destroying == true then return end
			TowerClone:Destroy()
			for i, towerName in ipairs(otherTowers) do
				if destroying == true then return end
				local TowerModel = Storage.Towers:FindFirstChild(towerName):FindFirstChildWhichIsA("Model")
				TowerModel.PrimaryPart = TowerModel.HumanoidRootPart
				MainUI.Rarity.TName.Text = towerName
				MainUI.Rarity.Rarity.Text = Storage.Towers:FindFirstChild(towerName).Rarity.Value
				local OtherTowerClone = TowerModel:Clone()
				OtherTowerClone.Parent = workspace
				table.insert(towersss,OtherTowerClone)
				OtherTowerClone.PrimaryPart = OtherTowerClone:FindFirstChild("HumanoidRootPart")
				OtherTowerClone:PivotTo(TowerOpenninCFrame)
				OtherTowerClone:ScaleTo(TowerScale)
				local oldcf = OtherTowerClone.PrimaryPart.CFrame
				OtherTowerClone.PrimaryPart.CFrame = oldcf * CFrame.Angles(0,math.rad(-180),0)
				EditParticles(FireWorkEffects, true)
				OtherTowerClone.HumanoidRootPart.Anchored = true
				local Animation = TowerModel:FindFirstChildWhichIsA("Animation")
				if Animation then
					local LoadedAnimation = OtherTowerClone:FindFirstChild("Humanoid"):LoadAnimation(Animation)
					LoadedAnimation:Play()
				end
				local initialCFrame = OtherTowerClone.PrimaryPart.CFrame
				local targetCFrame = initialCFrame * CFrame.Angles(0, math.rad(-180), 0)
				local tween = TweenService:Create(OtherTowerClone.PrimaryPart, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = targetCFrame})
				tween:Play()
				task.wait(1)
				if i < #otherTowers then
					OtherTowerClone:Destroy()
				end
			end
		end)

		Animation.Stopped:Connect(function()
			stopped = true
		end)
	end
end

local function StartDeletingTowers()
	if not DeletingTowers then
		DeletingTowers = true
	end
end

local function DeleteTowers()
	if DeletingTowers then
		if #TowersToDelete >= 1 then
			for i,towerKey in pairs(TowersToDelete) do
				Storage.Events.DeleteTower:FireServer(towerKey)
				warn("deleting "..towerKey)
				table.remove(TowersToDelete,i)
			end
			task.wait(0.1)
			DeletingTowers = false
			SelectedTower = nil
			SelectedTowerKey = nil
			updateInventory()
			updateSelected()
			updateTowers()
		end
	end
end

local animClassEq = AnimationComponent.new(SelectedFrame.EquipButton)
local UnequipAllButton = AnimationComponent.new(MainUI.InventoryFrame.MainFrame.UnequipAllButton)
local DeleteTowerButton = AnimationComponent.new(MainUI.InventoryFrame.MainFrame.Deletebutton)

animClassEq:Init(nil, function()
	if SelectedTower and SelectedTowerKey then
		local PlayerData = getPlayerData()
		local TowerTable = PlayerData.EquippedTowers
		local FoundIt = false
		for _, Tower in pairs(TowerTable) do
			if Tower.Name == SelectedTower then
				FoundIt = true
				break
			end
		end
		if not FoundIt then
			if #TowerTable >= 4 then
				PopupComponent:Spawn("Error","You Equipped Max Amount Of Towers",1)
				return
			end
			Storage.Events.EquipTower:FireServer(SelectedTower, SelectedTowerKey)
			task.wait(0.1)
			updateSelected()
			updateInventory()
		else
			warn("unequipping")
			Storage.Events.UnequipTower:FireServer(SelectedTower, SelectedTowerKey)
			task.wait(0.1)
			updateSelected()
			updateInventory()
		end
	end
end)

UnequipAllButton:Init(nil,function()
	task.spawn(function()
		local playerData = getPlayerData()
		for _,TowerTable in pairs(playerData.EquippedTowers) do
			Storage.Events.UnequipTower:FireServer(TowerTable.Name, TowerTable.Key)
		end
		task.wait(0.1)
		updateTowers()
		updateInventory()
		updateSelected()
	end)
end)

DeleteTowerButton:Init(nil,function()
	if not DeletingTowers then
		StartDeletingTowers()
	else
		DeleteTowers()
	end
end)

updateTowers()
updateInventory()

SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
	if SearchBar.Text == "" then
		updateInventory()
	else
		SearchInventory(SearchBar.Text)
	end
end)

Storage.Events.BuyTowerClient.OnClientEvent:Connect(function(towerName)
	updateInventory()
	AnimateTowerBuying(towerName)
end)

OnTowerAdded:Connect(updateTowers)
OnTowerChanged:Connect(updateTowers)
OnSelectedChanged:Connect(updateSelected)
