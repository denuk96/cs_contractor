require 'open3'

namespace :analyzes do
  task gemini_check: :environment do
    trending_items = SkinItem.trending(sort_by: 'top_signals')
    csv_data = CsvExportService.new(trending_items).call

    # Ensure the directory exists
    tmp_dir = Rails.root.join('tmp')
    Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)

    csv_path = tmp_dir.join("data.csv")
    File.write(csv_path, csv_data)

    prompt_path = Rails.root.join("doc", "manipulation_detection_prompt.md")
    prompt_text = File.read(prompt_path)
    output_path = tmp_dir.join("analysis.md")

    # Combine the @file syntax with the prompt text
    full_prompt = "@#{csv_path} #{prompt_text}"

    puts "Processing #{csv_path} with GEMINI_IGNORE override..."

    # Open3.capture3 allows passing an environment hash as the first argument
    env = { "GEMINI_IGNORE" => "" }
    stdout, stderr, status = Open3.capture3(env, "gemini", "-p", full_prompt)

    if status.success?
      File.write(output_path, stdout)
      puts "Done! Result saved to #{output_path}"
    else
      puts "Error from Gemini CLI:"
      # If the ignore logic is still failing, stderr will contain the path error
      puts stderr
    end
  end
end
