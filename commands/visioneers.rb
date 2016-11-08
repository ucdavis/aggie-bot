module ChatBotCommand
  class Visioneers
    TITLE = "Visioneers"
    REGEX = /^visioneers/
    COMMAND = "visioneers"
    DESCRIPTION = "Outputs the time left for productivity in minutes"

    def run(message, channel, private_allowed)
      if(Time.now.hour < 17)
        return "There are #{((Time.new(Time.now.year, Time.now.month, Time.now.day, 17, 0, 0) - Time.now) / 60).to_i} minutes of productivity remaining in the day."
      else
        return "There are no minutes of productivity remaining in the day."
      end
    end

    @@instance = Visioneers.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
