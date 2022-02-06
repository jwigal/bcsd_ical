class BcsdIcal::Filter
  def original_icalendar
    @original_icalendar ||= Icalendar::Calendar.parse(ical_source)[0]
  end

  def original_csv
    CSV.generate do |csv|
      csv << %w(uid start end summary description)
      original_icalendar.events.each do |event|
        csv << [
          event.uid, event.dtstart.to_s, event.dtend.to_s, event.summary, event.description
        ]
      end
    end
  end

  def filtered_calendar
    Icalendar::Calendar.new.tap do |calendar|
      original_icalendar.events.each do |original_event|
        next if skip?(original_event.summary)
        calendar.event do |new_event|
          new_event.dtstart = original_event.dtstart
          new_event.dtend = original_event.dtend
          new_event.summary = original_event.summary
          new_event.description = original_event.description
          new_event.transp = 'TRANSPARENT'
          new_event.uid = original_event.uid
        end
      end
    end
  end

  def skip?(text)
    return false if !text.present?
    return false if text =~ /ptsa/i
    return true if text =~ /(FRES|TCMS|CRPS|Board of Education)/
    false
  end

  def ical_source
    return File.read("original_feed.ics") if File.exists?("original_feed.ics")
    File.open("original_feed.ics",'wb') do |file|
      file.write HTTParty.get("https://www.bcsd.org/site/handlers/icalfeed.ashx?MIID=17905").body
    end
    File.read("original_feed.ics")
  end
end
