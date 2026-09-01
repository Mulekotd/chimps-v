#ifndef CHIMPSV_PLATFORM_H
#define CHIMPSV_PLATFORM_H

#include <stdint.h>

#define CHIMPSV_UART_TX_DATA   (*(volatile uint32_t *)0xffff0000u)
#define CHIMPSV_UART_TX_STATUS (*(volatile uint32_t *)0xffff0004u)
#define CHIMPSV_UART_RX_DATA   (*(volatile uint32_t *)0xffff0008u)
#define CHIMPSV_UART_RX_STATUS (*(volatile uint32_t *)0xffff000cu)
#define CHIMPSV_SIM_CONTROL    (*(volatile uint32_t *)0xffff0010u)

#endif
