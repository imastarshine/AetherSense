local Timer = {} :: TimerClass
Timer.__index = Timer

export type Timer = {
	id: number | string,
	enabled: boolean,
	_delayTime: number,
	_task: thread?,
	callbacks: {[number]: () -> ()},
	_callback_id: number,

	Add: (self: Timer, callback: () -> ()) -> number,
	RemoveCallback: (self: Timer, callbackId: number) -> (),
	Start: (self: Timer) -> (),
	Stop: (self: Timer) -> (),
	Destroy: (self: Timer) -> (),
	GetDelayTime: (self: Timer) -> number,
}

export type TimerClass = {
	new: (id: number | string, delayTime: number?) -> Timer,
	Get: (id: number | string) -> Timer?,
	Wait : (id: number | string, timeOut: number) -> Timer?,
	__index: typeof(Timer)
}

local timers: {[string | number]: Timer} = {}

function Timer.new(id: number | string, delayTime: number?): Timer
	if timers[id] then return timers[id] end

	local self = setmetatable({}, Timer)

	self.id = id
	self.enabled = false
	self._delayTime = math.clamp(delayTime or 1, 0.001, 10e7)
	self._task = nil
	self.callbacks = {}
	self._callback_id = 0

	timers[id] = self :: any
	return self :: any
end

function Timer.Get(id: number | string): Timer?
	return timers[id]
end

function Timer.Wait(id: number | string, timeOut: number): Timer?
	local start = os.clock()
	while os.clock() - start < timeOut do
		if timers[id] then return timers[id] end
		task.wait(0.1)
	end
	return nil
end

function Timer:Add(callback: () -> ()): number
	self._callback_id += 1
	self.callbacks[self._callback_id] = callback
	return self._callback_id
end

function Timer:RemoveCallback(callbackId: number)
	self.callbacks[callbackId] = nil
end

function Timer:Start()
	if self.enabled or self._task then return end

	self.enabled = true
	self._task = task.spawn(function()
		while self.enabled do
			task.wait(self._delayTime)
			if not self.enabled then break end

			for id, callback in pairs(self.callbacks) do
				local success, exception = pcall(callback)
				if not success then
					warn(`[Timer {self.id}] Callback error (ID: {id}): {exception}`, 2)
					self.callbacks[id] = nil
				end
			end
		end
	end)
end

function Timer:Stop()
	self.enabled = false
	if self._task then
		task.cancel(self._task)
		self._task = nil
	end
end

function Timer:Destroy()
	self:Stop()
	table.clear(self.callbacks)
	timers[self.id] = nil
end

function Timer:GetDelayTime(): number
	return self._delayTime
end

return Timer
