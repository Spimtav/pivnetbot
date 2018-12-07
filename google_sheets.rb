require 'bundler'
Bundler.require


module GoogleSheets
  def self.initialize(settings)
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(settings.google_sheets_credentials))

    spreadsheet = session.spreadsheet_by_title(settings.spreadsheet_title)
    worksheet = spreadsheet.worksheets.first
    worksheet.rows.each { |row| puts row.first(6).join(" | ") }
    worksheet
  end

  def self.write_line(settings, line)
    settings.google_sheets_worksheet_object.insert_rows(settings.google_sheets_worksheet_object.num_rows + 1, [line])
    settings.google_sheets_worksheet_object.save
  end
end
