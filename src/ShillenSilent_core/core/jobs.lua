local registry = require("ShillenSilent_core.features.registry")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")

local jobs = {
	started = false,
	next_tick = {},
	guarded = {},
}

local function get_tick()
	return (util and util.get_tick_count and util.get_tick_count()) or 0
end

local function run_job(job)
	local module = job.module and require(job.module) or nil
	local fn = module and module[job.fn]
	if type(fn) == "function" then
		pcall(fn)
	end
end

local function collect_jobs()
	local out = {}
	local manifests = registry.list()
	for i = 1, #manifests do
		local manifest = manifests[i]
		local manifest_jobs = manifest.jobs or {}
		for j = 1, #manifest_jobs do
			local job = manifest_jobs[j]
			out[#out + 1] = job
		end
	end
	return out
end

function jobs.start()
	if jobs.started then
		return false
	end
	jobs.started = true
	local registered = collect_jobs()
	util.create_thread(function()
		while true do
			local now = get_tick()
			for i = 1, #registered do
				local job = registered[i]
				local id = job.id or (tostring(job.module) .. "." .. tostring(job.fn))
				local interval = tonumber(job.interval_ms) or 1000
				if now >= (jobs.next_tick[id] or 0) then
					jobs.next_tick[id] = now + interval
					run_job(job)
				end
			end
			util.yield(0)
		end
	end)
	return true
end

function jobs.run_guarded_job(job_key, job_fn, on_busy)
	if type(job_fn) ~= "function" then
		return false
	end

	local key = tostring(job_key or "")
	if key == "" then
		return false
	end

	if jobs.guarded[key] then
		if type(on_busy) == "function" then
			pcall(on_busy)
		end
		return false
	end

	jobs.guarded[key] = true
	local ok_spawn, spawn_err = pcall(util.create_job, function()
		local ok_job, job_err = pcall(job_fn)
		jobs.guarded[key] = nil
		if not ok_job then
			notify_core.raw(
				i18n.t("notify.async_job_error_title"),
				i18n.t("notify.async_job_error", { key = key, error = tostring(job_err) }),
				3000
			)
		end
	end)

	if not ok_spawn then
		jobs.guarded[key] = nil
		notify_core.raw(
			i18n.t("notify.async_job_error_title"),
			i18n.t("notify.async_job_error", { key = key, error = tostring(spawn_err) }),
			3000
		)
		return false
	end

	return true
end

return jobs
