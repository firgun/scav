
editor = {}

ui = ImguiContext:new()

local id_test_button = ui:getid()
local id_real_button = ui:getid()
local id_label       = ui:getid()

local button_ids = ui:getids(10)

editor.p_x = 100
editor.p_y = 100

editor.is_open = true

function editor.update()
	print(editor.is_open)

	local was_open = editor.is_open

	editor.is_open, editor.p_x, editor.p_y = ui:panel_begin(editor.is_open, editor.p_x, editor.p_y, 'Super Panel')

	if editor.is_open then
		ui:label(id_label, 'Label')

		if ui:button(id_test_button, 'Button') then
			print('hello, world')
		end

		for i=1,10 do
			if ui:button(button_ids[i], 'Button') then
			end
			local text = ui:input_field('Hello, World')
			ui:space()
		end
	end

	ui:panel_end(was_open)

	ui:update()
end