require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'



def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  phone = phone.to_s.gsub(/[^\d]/, '')
  return phone if phone.length == 10
  return phone[1..10] if phone.length == 11 && phone[0] == '1'
  return ''
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_personal_letter(id, personal_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts personal_letter
  end
end

puts 'Event Manager Initialized!'
if File.exist?("event_attendees.csv") && File.exist?('form_letter.erb') then
  template_letter = ERB.new(File.read('form_letter.erb'))
  event_attendees = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  registration_hours = Hash.new(0)
  registration_week_days = Hash.new(0)
  event_attendees.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    personal_letter = template_letter.result(binding)
    save_personal_letter(id, personal_letter)
    phone = clean_phone(row[:homephone])
    registration_time = Time.strptime('EST/20/' + row[:regdate], '%Z/%C/%m/%d/%Y %H:%M')
    registration_hours[registration_time.hour] += 1
    registration_week_days[registration_time.wday] += 1
    puts phone
    puts registration_time
  end
  p registration_hours
  p registration_week_days
end