require "httparty"
require "nokogiri"
require "json"

class Yad2Scraper
    def initialize
        @user_agent ||= "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36"
        @url ||= "https://www.yad2.co.il/realestate/rent/apartment-in-ramat-gan?city=8600&property=1&rooms=3--1&price=3000-5000&forPartners=1&Immediate=1"
    end

    def rooms_format(num)
        i, f = num.to_i, num.to_f
        i == f ? i : f
    end

    def price_format(num)
        i = num.gsub(" ₪", "")
        (i.gsub(",", "")).to_i
    end

    def subtitle_format(str)
        i = str.gsub("דירה,", "")
        i.lstrip
    end

    def title_format(str)
        str.gsub("\"", "")
    end

    def date_format(str)
        if str.include?("עודכן היום")
            i = str.gsub("עודכן היום", "")
            i.lstrip
        elsif str.include?("עודכן ב")
            i = str.gsub("עודכן ב", "")
            i.lstrip
        else
            Time.now.strftime('%d/%m/%Y')
        end
    end

    def scraper
        page = HTTParty.get(@url, {
            headers: { "User-Agent": @user_agent }
        })
        parse_page = Nokogiri::HTML(page)

        listings_array = []

        parse_page.css('div.feed_item-v4.accordion.showPU.desktop').each do |item|
            id = item['itemid']
            title = item.css('span.title').text.strip
            subtitle = item.css('span.subtitle').text.strip
            price = item.css('div.price').text.strip
            rooms = item.css('span.val')[0].text.strip
            floor = item.css('span.val')[1].text.strip
            size = item.css('span.val')[2].text.strip
            published_at = item.css('span.date').text.strip

            listings_array.push({
                id: id,
                title: title_format(title),
                subtitle: subtitle_format(subtitle),
                price: price_format(price),
                rooms: rooms_format(rooms),
                floor: floor.to_i,
                size: size.to_i,
                published_at: date_format(published_at)
            })

            listings_array.sort_by { |hash| hash['published_at'].to_i }
        end

        listings_object = {
            listings_total: listings_array.count,
            listings: listings_array
        }

        File.open("listings.json", "w") do |file|
            file.write(JSON.pretty_generate(listings_object))
        end
    end

    def start
        scraper
    end
end

scraper = Yad2Scraper.new.start