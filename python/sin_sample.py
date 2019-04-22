import numpy as np
import matplotlib.pyplot as plt

x=np.arange(-10,10,0.1)
y=np.sin(x)
y2=np.cos(x)

plt.plot(x, y,linestyle="--")
plt.plot(x, y2)
plt.show()
