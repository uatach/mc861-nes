#import evdev
from evdev import InputDevice, categorize, ecodes

#creates object 'gamepad' to store the data
#you can call it whatever you like
gamepad = InputDevice('/dev/input/event15')

#prints out device info at start
print(gamepad)

#evdev takes care of polling the controller in a loop
for event in gamepad.read_loop():
    #filters by event type

    print("**------------------------------")
    if event.type == ecodes.EV_KEY:
        print(event)
    else:
        print(event.value)

#Não entendi o porque o código ev_key dos direcionais não 
