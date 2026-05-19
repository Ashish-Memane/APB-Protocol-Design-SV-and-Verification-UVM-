# APB-Protocol-Design-SV-and-Verification-UVM-
Developed  an APB protocol with one master and three slaves (UART, SPI and GPIO) and verified it with the UVM TB.

📘 APB Protocol Design & Verification (RTL + UVM Ready)
📌 Overview

This project implements a complete AMBA APB (Advanced Peripheral Bus) subsystem, including:

APB Master
  1. APB Interconnect (Decoder + Mux)

Peripherals:
  1. GPIO
  2. UART
  3. SPI
     
APB Interconnect

System-level integration
UVM-ready interface architecture

                 APB MASTER
                      |
                      |
            +-------------------+
            | APB INTERCONNECT  |
            | (Address Decoder) |
            +-------------------+
             |       |        |
            GPIO    UART     SPI

⚙️ Features
✔ APB Master
  FSM-based design (IDLE → SETUP → ACCESS)
  Supports read/write transactions
  Generates APB control signals
✔ APB Interconnect
  Address decoding
  Slave selection
  PRDATA / PREADY multiplexing
  Error handling (PSLVERR)
✔ GPIO Peripheral
  Direction register
  Output register
  Input register support
✔ UART Peripheral
  Simple receive/transmit model
  Status register support
✔ SPI Peripheral
  Basic transfer logic
  Busy / done status tracking

  🔌 APB Protocol Highlights
Synchronous protocol (PCLK-based)
Two-phase transfer:
SETUP phase
ACCESS phase
PSEL + PENABLE handshake
PREADY for wait states
PSLVERR for error handling


