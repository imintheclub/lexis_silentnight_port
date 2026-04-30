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

local function current_ui_mode()
	return _G.ShillenSilent_ForceStop == true and "controller" or "click"
end

local function infer_ui_mode(module_name)
	if type(module_name) ~= "string" then
		return nil
	end
	if module_name:match("%.click$") then
		return "click"
	end
	if module_name:match("%.controller$") then
		return "controller"
	end
	return nil
end

local function resolve_job_fn(job)
	if job.disabled then
		return nil
	end
	if type(job.fn) == "function" then
		return job.fn
	end
	if not job.module then
		job.disabled = true
		return nil
	end
	if job.ui_mode and not package.loaded[job.module] then
		return nil
	end

	local ok, module = pcall(require, job.module)
	if ok and type(module) == "table" and type(module[job.fn_name]) == "function" then
		job.fn = module[job.fn_name]
		return job.fn
	end

	job.disabled = true
	notify_core.push("app.name", "notify.module_failed", 3000, { module = tostring(job.module) })
	return nil
end

local function run_job(job)
	local fn = resolve_job_fn(job)
	if type(fn) == "function" then
		pcall(fn)
	end
end

local function resolve_job(job)
	local id = job.id or (tostring(job.module) .. "." .. tostring(job.fn))
	local interval = tonumber(job.interval_ms) or 1000

	return {
		id = id,
		interval = interval,
		module = job.module,
		fn = type(job.fn) == "function" and job.fn or nil,
		fn_name = type(job.fn) == "string" and job.fn or nil,
		ui_mode = infer_ui_mode(job.module),
	}
end

local function collect_jobs()
	local out = {}
	local manifests = registry.list()
	for i = 1, #manifests do
		local manifest = manifests[i]
		local manifest_jobs = manifest.jobs or {}
		for j = 1, #manifest_jobs do
			local job = manifest_jobs[j]
			local resolved = resolve_job(job)
			if resolved then
				out[#out + 1] = resolved
			end
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
				if (not job.ui_mode or job.ui_mode == current_ui_mode()) and now >= (jobs.next_tick[job.id] or 0) then
					jobs.next_tick[job.id] = now + job.interval
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
