local config = require("ShillenSilent_core.ui.click.config")

local animator = { values = {}, frame = 0 }

local function lerp(a, b, t)
	return a + (b - a) * t
end

function animator.clamp01(v)
	if v < 0 then
		return 0
	end
	if v > 1 then
		return 1
	end
	return v
end

function animator.motion_disabled()
	return config.motion and config.motion.reduced_motion
end

function animator.motion_speed(token_value, fallback)
	if animator.motion_disabled() then
		return 1.0
	end
	return token_value or fallback or 0.16
end

function animator.to(key, target, speed)
	if animator.motion_disabled() then
		animator.values[key] = { v = target, seen = animator.frame }
		return target
	end

	local node = animator.values[key]
	if not node then
		node = { v = target, seen = animator.frame }
		animator.values[key] = node
		return target
	end

	node.v = lerp(node.v, target, speed)
	if math.abs(node.v - target) < 0.01 then
		node.v = target
	end
	node.seen = animator.frame
	return node.v
end

function animator.vec2(key, target_x, target_y, speed)
	local x = animator.to(key .. ":x", target_x, speed)
	local y = animator.to(key .. ":y", target_y, speed)
	return x, y
end

function animator.prune(max_age)
	local cutoff = animator.frame - max_age
	for key, node in pairs(animator.values) do
		if not node.seen or node.seen < cutoff then
			animator.values[key] = nil
		end
	end
end

function animator.blend_color(c1, c2, t, out)
	local tt = animator.clamp01(t)
	local inv = 1 - tt
	out = out or {}
	out.r = math.floor((c1.r or 0) * inv + (c2.r or 0) * tt)
	out.g = math.floor((c1.g or 0) * inv + (c2.g or 0) * tt)
	out.b = math.floor((c1.b or 0) * inv + (c2.b or 0) * tt)
	out.a = math.floor((c1.a or 255) * inv + (c2.a or 255) * tt)
	return out
end

return animator
