namespace :batch do
  desc "Perform system check and send reports"
  task system_check: :environment do
    puts "Starting system check at #{Time.current}"
    
    begin
      MUtils.perform_system_check
      puts "System check completed successfully at #{Time.current}"
    rescue => e
      puts "System check failed: #{e.class} - #{e.message}"
      puts e.backtrace.join("\n")
      raise e
    end
  end
end