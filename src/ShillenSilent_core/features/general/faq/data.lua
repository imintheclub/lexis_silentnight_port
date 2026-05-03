local data = {
	feature_id = "faq",
	label_key = "feature.faq.name",
	categories = {
		{
			id = "project",
			label_key = "faq.category.project",
			items = {
				{ question_key = "faq.q.open_source", answer_key = "faq.a.open_source" },
				{ question_key = "faq.q.free", answer_key = "faq.a.free" },
			},
		},
		{
			id = "discord",
			label_key = "faq.category.discord",
			items = {
				{ text_key = "faq.discord.text" },
			},
		},
		{
			id = "setup",
			label_key = "faq.category.setup",
			items = {
				{ question_key = "faq.q.not_showing", answer_key = "faq.a.not_showing" },
				{ question_key = "faq.q.switch_controller", answer_key = "faq.a.switch_controller" },
				{ question_key = "faq.q.mouse", answer_key = "faq.a.mouse" },
			},
		},
		{
			id = "safety",
			label_key = "faq.category.safety",
			items = {
				{ question_key = "faq.q.safe", answer_key = "faq.a.safe" },
			},
		},
		{
			id = "payouts",
			label_key = "faq.category.payouts",
			items = {
				{ question_key = "faq.q.pacific_bonus", answer_key = "faq.a.pacific_bonus" },
				{ question_key = "faq.q.transaction_error", answer_key = "faq.a.transaction_error" },
			},
		},
	},
}

return data
