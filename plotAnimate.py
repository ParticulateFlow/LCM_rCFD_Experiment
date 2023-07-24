
import pandas as pd
from getData import getDataFromStream
import matplotlib.pyplot as plt
from matplotlib import pyplot as plt
from matplotlib.animation import FuncAnimation
from datetime import datetime
import seaborn as sns
from matplotlib.widgets import Button

sns.set()

d = getDataFromStream(host = "127.0.0.1", port=4000)
global data, t_start
t_start = datetime.strptime(d['Time'], '%d-%b-%Y %H:%M:%S')
data = [[]]*len(d.keys())
for i,v in enumerate(d.items()):
    data[i] = [v[1]]
data[0]=[int(0)]


fig, ax = plt.subplots(ncols=1, nrows=3)
fig.canvas.manager.full_screen_toggle()
fig.tight_layout(pad=5.0)

def plot():
    # mass flow
    ax[0].plot(data[0], data[1], color='red') # warmFlow
    ax[0].plot(data[0], data[2], color='blue') # coldFlow
    ax[0].plot(data[0], [sum(x) for x in zip(data[1], data[2])], color='black', linestyle='dashed') # coldFlow
    ax[0].legend(['warm flow','cold flow','sum'], loc='upper right')
    ax[0].set_ylim([0, 40])
    ax[0].set_ylabel('ml/s')
    ax[0].set_title('Mass flow')
    # temperature
    ax[1].plot(data[0], data[3], color='blue') # coldInlet
    ax[1].plot(data[0], data[4], color='red') # warmInlet
    ax[1].plot(data[0], data[5], color='black') # outlet
    ax[1].legend(['cold','warm','outlet'], loc='upper right')
    ax[1].set_ylim([20, 80])
    ax[1].set_ylabel('C')
    ax[1].set_title("System temperature")
    # temperature box
    ax[2].plot(data[0], data[6], color='orange') # h=35mm
    ax[2].plot(data[0], data[7], color='green') # h=95mm
    ax[2].plot(data[0], data[8], color='purple') # h=155mm
    ax[2].plot(data[0], data[9], color='cyan') # h=215mm
    ax[2].set_ylim([20, 80])
    ax[2].legend(['h=35mm','h=95mm','h=155mm','h=255mm'], loc='upper right')
    ax[2].set_ylabel('C')
    ax[2].set_title("Box temperatures")

    plt.suptitle("rCFD Experiment")

def callbackClear(event):
    global data, t_start
    d = getDataFromStream(host = "127.0.0.1", port=4000)
    t_start = datetime.strptime(d['Time'], '%d-%b-%Y %H:%M:%S')
    data = [[]]*len(d.keys())
    for i,v in enumerate(d.items()):
        data[i] = [v[1]]
    data[0]=[int(0)]
    plot()
    print("Data cleared")

axclear = fig.add_axes([0.65, 0.925, 0.1, 0.05])
bnclear = Button(axclear, 'Clear Data')
bnclear.on_clicked(callbackClear)
plot()

def update(frame):
    d = getDataFromStream(host = "127.0.0.1", port=4000)
    t_now = datetime.strptime(d['Time'], '%d-%b-%Y %H:%M:%S')
    d['Time'] = int((t_now - t_start).total_seconds())
    for i,v in enumerate(d.items()):
        data[i].append(v[1])
    
    for a in ax: a.clear()
    plot()

animation = FuncAnimation(fig, update, interval=200,cache_frame_data=False)
plt.show()
