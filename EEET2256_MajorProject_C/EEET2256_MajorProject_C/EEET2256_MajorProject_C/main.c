
// Created: 3/10/2019 12:26:15 AM

#include <avr/io.h>
#include <stdio.h>

void init_UART(void);
void send_UART(int data);
void string_UART(unsigned char *string);
void msdelay(unsigned int msec);
int ReadKP();
int convtodec(int asc);
int combine(int one, int two);
int addition(int one, int two);
int subtraction(int one, int two);
int multiplication(int one, int two);
int division(int one, int two);

////////////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////
int main(void)
{
	volatile int keypad;
	volatile int digit_first;
	volatile int digit_second;
	volatile int digit_operator1;
	volatile int digit_operator2;
	volatile int dec_first;
	volatile int dec_second;
	volatile int comdigit_first;
	volatile int comdigit_second;
	volatile int result;
	volatile unsigned char string[4];
	volatile unsigned int table[256] = { 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,		// 0 - 15
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 16 - 31
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 32 - 47
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 48 - 63
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 64 - 79
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 80 - 95
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 96 - 111
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 112 - 127
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 128 - 143
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,			// 144 - 159
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 54,			// 160 - 175
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 52, 63, 63, 53, 63,			// 176 - 191
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 57,			// 192 - 207
										63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 55, 63, 63, 56, 63,			// 208 - 223
										63, 63, 63, 63, 63, 63, 63, 35, 63, 63, 63, 63, 63, 51, 63, 63,			// 224 - 239
										63, 63, 63, 42, 63, 63, 48, 63, 63, 49, 63, 63, 50, 63, 63, 63 };		// 240 - 255
	DDRC = 0x15;
	PORTC = 0xEA;
	
	init_UART();
	
	send_UART(12); //new page
	msdelay(150);
	
	send_UART(128); //set cursor on start
	msdelay(150);
	
    while (1) 
    {
		//first digit
		keypad = ReadKP();
		digit_first = table[keypad];
		send_UART(digit_first);
		msdelay(1000);
		dec_first = convtodec(digit_first); //convert to decimal value
		
		keypad = 0;
		//second digit
		keypad = ReadKP();
		digit_second = table[keypad];
		send_UART(digit_second);
		msdelay(1000);
		dec_second = convtodec(digit_second); //convert to decimal value
		
		//combine first two digits
		comdigit_first = combine(dec_first, dec_second);
		
		//clear variables to be reused
		digit_first = 0;
		dec_first = 0;
		digit_second = 0;
		dec_second = 0;
		keypad = 0;
		
		//third digit
		keypad = ReadKP();
		digit_first = table[keypad];
		send_UART(digit_first);
		msdelay(1000);
		dec_first = convtodec(digit_first); //convert to decimal value
		
		keypad = 0;
		//fourth digit
		keypad = ReadKP();
		digit_second = table[keypad];
		send_UART(digit_second);
		msdelay(1000);
		dec_second = convtodec(digit_second); //convert to decimal value
		
		//combine last two digits
		comdigit_second = combine(dec_first, dec_second);
		
		//error check! value should not be larger than 99.
		if ((comdigit_first > 99) || (comdigit_second > 99))
		{
			send_UART(33);
			msdelay(150);
			string_UART("ERROR");
			send_UART(33);
			msdelay(150);
		}
		else
		{
			//read the operator
			keypad = ReadKP();
			digit_operator1 = table[keypad];
			send_UART(digit_operator1);
			msdelay(1000);
			
			if(digit_operator1 == 0x2A) //if * is pressed
			{
				keypad = ReadKP();
				digit_operator2 = table[keypad];
				send_UART(digit_operator2);
				msdelay(1000);
				
				if(digit_operator2 == 0x2A) //* is pressed as second operator
				{
					send_UART(61);
					msdelay(150);
					result = addition(comdigit_first, comdigit_second);
					sprintf(string, "%d", result);
					string_UART(string);
				}
				else if(digit_operator2 == 0x23) //# is pressed as second operator
				{
					send_UART(61);
					msdelay(150);
					result = multiplication(comdigit_first, comdigit_second);
					sprintf(string, "%d", result);
					string_UART(string);
				}
				else
				{
					send_UART(33);
					msdelay(150);
					string_UART("ERROR");
					send_UART(33);
					msdelay(150);
				}
			}
			else if (digit_operator1 == 0x23) //if # is pressed
			{
				keypad = ReadKP();
				digit_operator2 = table[keypad];
				send_UART(digit_operator2);
				msdelay(1000);
				
				if(digit_operator2 == 0x23) //# is pressed as second operator
				{
					send_UART(61);
					msdelay(150);
					result = subtraction(comdigit_first, comdigit_second);
					sprintf(string, "%d", result);
					string_UART(string);
				}
				else if(digit_operator2 == 0x2A) //* is pressed as second operator
				{
					send_UART(61);
					msdelay(150);
					result = division(comdigit_first, comdigit_second);
					sprintf(string, "%d", result);
					string_UART(string);
				}
				else
				{
					send_UART(33);
					msdelay(150);
					string_UART("ERROR");
					send_UART(33);
					msdelay(150);
				}
			}
			else //for any other input, which is an error
			{
				send_UART(33);
				msdelay(150);
				string_UART("ERROR");
				send_UART(33);
				msdelay(150);
			}
		}
		
		while (1) //to reset the calculator
		{
			digit_operator1 = 0;
			//read the operator
			keypad = ReadKP();
			digit_operator1 = table[keypad];
			
			if (digit_operator1 == 0x23)
			{
				send_UART(12); //new page
				msdelay(150);
				
				send_UART(128); //set cursor on start
				msdelay(150);
				
				//clear all variables to be reused
				digit_first = 0;
				dec_first = 0;
				comdigit_first = 0;
				digit_second = 0;
				dec_second = 0;
				comdigit_second = 0;
				digit_operator1 = 0;
				digit_operator2 = 0;
				keypad = 0;
				result = 0;
				break;
			}
			else
			{
				//do nothing
			}
		}
    }
}

////////////////////////////////////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////
void init_UART()
{
	//set the baud rate (this for 9600)
	UBRRH = 0x00;
	UBRRL = 0x4D;
	
	//set the UCSR registers
	UCSRC = (1 << URSEL) | (1 << UCSZ0) | (1 << UCSZ1) | (0 << USBS);
	UCSRB = (1 << RXEN) | (1 << TXEN);
}

void send_UART(int data)
{
	//check if UCSRA is ready (UDRE) has to be 1
	while((UCSRA & (1 << UDRE)) == 0);
	
	UDR = data;
}

void string_UART(unsigned char *string)
{
	while(*string != 0)
	{
		send_UART(*string++);
		msdelay(150);
	}
}

void msdelay(unsigned int msec)
{
	volatile unsigned int a;
	volatile unsigned int b;
	
	for(a=0;a<msec;a++)
	{
		for(b=0;b<301;b++); //1 ms
	}
}

int ReadKP()
{
	volatile int pincval;
	volatile unsigned char counter = 0;
	
	while (counter == 0)
	{
		PORTC = 0xFB; // for column 1
		msdelay(20);
		if (PORTC != PINC)
		{
			pincval = PINC;
			counter = 1;
		}
		else
		{
			//do nothing
		}
		PORTC = 0xFE; // for column 2
		msdelay(20);
		if (PORTC != PINC)
		{
			pincval = PINC;
			counter = 1;
		}
		else
		{
			//do nothing
		}
		PORTC = 0xEF; // for column 3
		msdelay(20);
		if (PORTC != PINC)
		{
			pincval = PINC;
			counter = 1;
		}
		else
		{
			//do nothing
		}
	}
	return pincval;
}

int convtodec(int asc)
{
	volatile int dectable[64] = {255, 255, 255, 255, 255, 255, 255, 255,		// 0 - 7
								255, 255, 255, 255, 255, 255, 255, 255,			// 8 - 15
								255, 255, 255, 255, 255, 255, 255, 255,			// 16 - 23
								255, 255, 255, 255, 255, 255, 255, 255,			// 24 - 31
								255, 255, 255, 255, 255, 255, 255, 255,			// 32 - 39
								255, 255, 255, 255, 255, 255, 255, 255,			// 40 - 47
								0, 1, 2, 3, 4, 5, 6, 7,							// 48 - 55
								8, 9, 255, 255, 255, 255, 255, 255};			// 56 - 63
	volatile int dec;
	dec = dectable[asc];
	return dec;
}

int combine(int one, int two)
{
	volatile int combination;
	
	combination = (one * 10) + two;
	return combination;
}

int addition(int one, int two)
{
	volatile int add = 0;;
	add = one + two;
	return add;
}

int subtraction(int one, int two)
{
	volatile int subtract = 0;
	subtract = one - two;
	return subtract;
}

int multiplication(int one, int two)
{
	volatile int mult = 0;
	mult = one * two;
	return mult;
}

int division(int one, int two)
{
	volatile int div = 0;
	div = one / two;
	return div;
}


