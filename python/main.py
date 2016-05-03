import memcard_driver

def main():
  driver = memcard_driver.MemCardDriver('COM3')
  
  while 1:
    packet = driver.Pop()
    print packet
  
if __name__ == "__main__":
  main()