module Echotunes
  module HtmlHelpers

    def human_time(seconds)
      sec = seconds.to_i % 60
      min = seconds.to_i / 60
      time = "#{min}m"
      time << "#{sec}s" if sec > 0
      time
    end

    # Has 3 positions (1 for ignnore/off)
    def toggle_slider(name, off, on)
      dom_id = "#{name}_toggle_slider"
      disabled = 'Ignore'

      content_for :js_onload do
        %Q{
        $("##{dom_id}").slider({
          value: 0,
          min: 0,
          max: 2,
          step: 1,
          orientation: "vertical",
          slide: function(event, ui){
            $('##{name}').val(ui.value-1);
            switch(ui.value){
              case 0:
                var txt = '#{disabled}';
                break;
              case 1:
                var txt = '#{off}';
                break;
              case 2:
                var txt = '#{on}';
                break;
            }

            $('##{name}_title .vals').text(txt);
          }
        });}
      end

      out = %Q{
        <p>
          <h6 id="#{name}_title">#{name}: <span class="vals">#{disabled}</span></h6>
          <div class="vertical_slider" id="#{dom_id}"></div>
        </p>
        <input type="hidden" name="#{name}" id="#{name}" value=""/>
      }


      out
    end

    def dual_slider(name, lo, hi)
      dom_id = "#{name}_slider"

      content_for :js_onload do
        %Q{
        $("##{dom_id}").slider({
          values: [#{lo}, #{hi}],
          min: #{lo},
          max: #{hi},
          orientation: "horizontal",
          range: true,
          animate: true,
          slide: function(event, ui){
            $('##{name}_lo').val(ui.values[0]);
            $('##{name}_hi').val(ui.values[1]);
            $('##{name}_title .vals').text(ui.values[0] + ' - ' + ui.values[1]);
          }
        });}
      end

      out = %Q{
        <p>
          <h6 id="#{name}_title">#{name}: <span class="vals">#{lo} - #{hi}</span></h6>
          <div id="#{dom_id}"></div>
        </p>
      }

      [['lo', lo], ['hi', hi]].each do |title, val|
        out << %Q{<input type="hidden" name="#{name}[#{title}]" id="#{name}_#{title}"/>}
      end

      out
    end

    def select_tag(name, options)
      opts = options.map do |opt, title|
        title ||= opt.split('-').join(' ')
        %Q{<option value="#{opt}">#{title}</option>}
      end

      %Q{<select id="#{name}" name="#{name}">
           <option></option>
           #{opts.join}
         </select>}
    end
  end
end
