# menus
$env.config.menus = [
   {
      name: completion_menu
      only_buffer_difference: false
      marker: "| "
      type: {
         layout: ide
         min_completion_width: 0
         max_completion_width: 150
         max_completion_height: 25
         padding: 0
         border: false
         cursor_offset: 0
         description_mode: prefer_right
         min_description_width: 0
         max_description_width: 50
         max_description_height: 10
         description_offset: 1
         correct_cursor_pos: true
      }
      style: {
         text: green
         selected_text: green_reverse
         description_text: yellow
         match_text: {attr: u}
         selected_match_text: {attr: ur}
      }
   }
   {
      name: history_menu
      only_buffer_difference: true
      marker: "? "
      type: {layout: list, page_size: 10}
      style: {text: green, selected_text: green_reverse}
   }
   {
      name: help_menu
      only_buffer_difference: true
      marker: "? "
      type: {
         layout: description
         columns: 4
         col_width: 20
         col_padding: 2
         selection_rows: 4
         description_rows: 10
      }
      style: {text: green, selected_text: green_reverse, description_text: yellow}
   }
   {
      name: commands_menu
      only_buffer_difference: false
      marker: "# "
      type: {
         layout: columnar
         columns: 4
         col_width: 20
         col_padding: 2
      }
      style: {text: green, selected_text: green_reverse, description_text: yellow}
      source: {|buffer, position|
         $nu.scope.commands | where name =~ $buffer | each {|it| {value: $it.name description: $it.usage} }
      }
   }
   {
      name: vars_menu
      only_buffer_difference: true
      marker: "# "
      type: {layout: list, page_size: 10}
      style: {text: green, selected_text: green_reverse, description_text: yellow}
      source: {|buffer, position|
         $nu.scope.vars | where name =~ $buffer | sort-by name | each {|it| {value: $it.name description: $it.type} }
      }
   }
   {
      name: commands_with_description
      only_buffer_difference: true
      marker: "# "
      type: {
         layout: description
         columns: 4
         col_width: 20
         col_padding: 2
         selection_rows: 4
         description_rows: 10
      }
      style: {text: green, selected_text: green_reverse, description_text: yellow}
      source: {|buffer, position|
         $nu.scope.commands | where name =~ $buffer | each {|it| {value: $it.name description: $it.usage} }
      }
   }
]
