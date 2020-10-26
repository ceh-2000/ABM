from numpy import loadtxt
from keras.models import Sequential
from keras.layers import Dense
import csv

# split into input (X) and output (y) variables
X = []
y = []

# load the dataset and distribute to X and y
with open('keras/swz_pns_sample.csv') as csv_file:
  csv_reader = csv.reader(csv_file, delimiter=',')
  for row in csv_reader:
    X_list = []
    y_list = []
    X_list.append(int(row[2]))
    X_list.append(int(row[5]))
    X_list.append(int(row[6]))
    y_list.append(int(row[7]))
    X.append(X_list)
    y.append(y_list)

# 70-30 train test split
len_of_observations = len(X)
print("Number of observations: "+str(len_of_observations))
index = round(len_of_observations*0.7)
print("Index to split on: "+str(index))
X_train = X[:index]
X_test = X[index:]
y_train = y[:index]
y_test = y[index:]

# define the keras model
model = Sequential() # Model has the eight variable
model.add(Dense(12, input_dim=3, activation='relu')) # First layer has 12 nodes and gets 3 inputs (ReLU)
model.add(Dense(8, activation='relu')) # Second layer has 8 nodes (ReLU)
model.add(Dense(1, activation='sigmoid')) # Third layer has one node (sigmoid)


# compile the keras model with a metric to access accuracy after each epock
model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])

# Fit our model using epochs and batches
# Batch size is the number of dataset rows that we consider before updating the model weights
# Epochs = number of times we go through the entire dataset
model.fit(X_train, y_train, epochs=100, batch_size=10) # 100 epochs and batch size of 10

# Evaluate the keras model on test data
_, accuracy = model.evaluate(X_test, y_test)
print('Accuracy: %.2f' % (accuracy*100))

# Make class predictions with the model
predictions = model.predict_classes(X_test)

# Print predictions for the first 10 sample household observations
for i in range(10):
  print("Input data: "+str(X_test[i]))
  print("Predicted education: "+str(predictions[i]))
  print("Actual education: "+str(y_test[i]))



