#!/usr/bin/ruby
# Karras - Send Pazuzu back to hell!
# Mauro Eldritch @ Ministerio de Produccion Argentina - 2018
system("clear")                                     # Clear Screen
puts banner = `cat exorcist.dat`                    # Display Banner

puts "[✟] Slaying Pazuzu's minions... (Killing daemons)"
`docker ps | grep portainer | awk '{print "stop "$1}' | xargs docker`

puts "[✟] Pouring holy water upon Pazuzu's head... (Killing containers)"
`docker ps -a --filter volume=portainer_data_poc | grep portainer | awk '{print "container rm "$1}' | xargs docker `

puts "[✟] Burning Pazuzu's remains... (Destroying the volume)"
`docker volume rm portainer_data_poc`

puts "[✟] You're free to go... for now."
