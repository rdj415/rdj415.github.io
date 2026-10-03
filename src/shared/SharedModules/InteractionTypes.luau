--!strict

export type InteractionType = "Tap" | "Hold"

export type InteractionState = "Available" | "Busy" | "Locked" | "Repaired" | "Open" | "Collected" | "Disabled"

export type InteractableConfig = {
	InteractionId: string,
	InteractionType: InteractionType,
	HoldDuration: number,
	MaxDistance: number,
	Cooldown: number,
	ActionText: string,
	ObjectTitle: string,
	RequiredItem: string?,
	CurrentState: InteractionState,
}

export type InteractionRequestAction = "Interact" | "StartHold" | "CompleteHold" | "CancelHold"

export type InteractionResponse = {
	Success: boolean,
	Reason: string?,
	Message: string,
	State: InteractionState?,
	ItemAcquired: string?,
}

export type FeedbackEvent = {
	Type: "StateChanged" | "Notification" | "SoundTrigger" | "InventoryUpdated",
	Target: Instance?,
	State: InteractionState?,
	Message: string?,
	SoundKey: string?,
	Payload: { [string]: any }?,
}

export type ActiveHoldSession = {
	Player: Player,
	Target: Instance,
	StartTime: number,
	HoldDuration: number,
}

local InteractionTypes = {}
return InteractionTypes
