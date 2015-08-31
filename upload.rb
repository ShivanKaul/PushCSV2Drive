require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'

APPLICATION_NAME = 'foobar'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.pwd, '.credentials',
                             'token.json')
SCOPE = 'https://www.googleapis.com/auth/drive'

def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  file_store = Google::APIClient::FileStore.new(CREDENTIALS_PATH)
  storage = Google::APIClient::Storage.new(file_store)
  auth = storage.authorize

  if auth.nil? || (auth.expired? && auth.refresh_token.nil?)
    app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
    flow = Google::APIClient::InstalledAppFlow.new(
        client_id: app_info.client_id,
        client_secret: app_info.client_secret,
        scope: SCOPE)
    auth = flow.authorize(storage)
    puts "Credentials saved to #{CREDENTIALS_PATH}" unless auth.nil?
  end
  auth
end

# Initialize API
client = Google::APIClient.new(application_name: APPLICATION_NAME)
client.authorization = authorize
drive_api = client.discovered_api('drive', 'v2')
file_name = 'foo.txt'
mime_type = 'text/plain'
file = drive_api.files.insert.request_schema.new({
                                                     title: file_name,
                                                     mimeType: mime_type
                                                 })
file.parents = [{id: '<folderId>'}]

media = Google::APIClient::UploadIO.new(file_name, mime_type)

# Upload file
result = client.execute!(
    api_method: drive_api.files.insert,
    body_object: file,
    media: media,
    parameters: {
        uploadType: 'multipart',
        alt: 'json'})
if result.status == 200
  p result.data # For debugging
else
  puts "An error occurred: #{result.data['error']['message']}"
end
