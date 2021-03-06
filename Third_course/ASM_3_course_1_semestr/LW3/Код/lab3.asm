;Лабораторная работа №3
;Вариант 13:
;	Вычислить сумму положительных, произведение отрицательных и их разность,
;   а также определить минимальное и максимальное число.

; Макрос вывода сообщений на экран
print macro srting		
	push ax
	push dx
	mov dx, offset srting
	mov ah, 09h
	int 21h
	pop dx
	pop ax
endm

; Макрос вывода строки символов
input macro srting 	
	push ax 
	push dx
	mov dx, offset srting
	mov ah, 0Ah
	int 21h
	pop dx
	pop ax
endm



d1 SEGMENT para public 'data'

	in_str label byte   	 ; Cтрока символов (не более 6)
	razmer db 7              ; Размер буфера (6 символов и знак)
	kol db (?)               ; Количество введеных символов
	stroka db 7 dup (?)      ; Буфер ввода чисел
	number dw 5 dup (0)  	 ; Mассив чисел
		
	sumPos dw 0              ; Сумма положительных чисел
	mulNeg dw 0              ; Произведение отрицательных
	diffRez dw 0             ; Разность суммы и произведения
	min dw  29999            ; Минимальный  элемент
	max dw -29999            ; Максимальный элемент
	siz dw 5              	 ; Kоличество чисел
	
	
	lab3 db 'Laboratory work #3','$'
	author db 13,10, 'Sapozhnikov Vladislav 19-V-1'
	perevod db 10,13,'$'
	inputError db 'Input Error!', 10,10,'$'
	divByZeroError db 'Divition by zero!', 10,10,'$'
	overflow db 'Overflow!', 10,10,'$'
	sumPosText db 13,10, 'Sum of positive elements:                ','$'
	mulNegText db 13,10, 'Mul of negative element:                 ','$'
	diffResText db 13,10,'Difference of sum and multiplication:    ','$'
	maxElText db  13,10, 'Max element:                             ','$'
	minElText db  13,10, 'Min element:                             ','$'
	out_str db 6 dup (' '),'$'
	enter_please db 'Input number from -29999 to 29999: $'
	
	flag_err equ 1
d1 ENDS



st1 SEGMENT para stack 'stack'
	dw 100 dup (?)
st1 ENDS



;Точка входа в программу
c1 SEGMENT para public 'code'
	ASSUME cs:c1, ds:d1, ss:st1
start:	
	mov ax, d1
	mov ds, ax
	
	
	mov ax, 03h		;Установка текстового видеорежима, очистка экрана
	int 10h			;ah=0 (номер функции),al=3 (номер режима)
	
	print lab3		;вывод сообщения с номером работы
	print author	;вывод автора работы
	print perevod	;пропуск строки

;****************************************** Ввод элементов с проверкой *******************************************
    xor di,di		;di - номер числа в массиве
    mov cx, siz		;cx - размер массива
	
inputVal:	
	push cx
	
check:	
	print enter_please	;Вывод сообщения о вводе строки
	input in_str 		;Ввод числа в виде строки
	print perevod       ;Переход на новую строку
	
	call diapazon		;Проверка диапазона вводимых чисел (-29999,+29999)
	cmp bh, flag_err  	;Сравним bh и flag_err
	je inErr         	;Если равен 1 сообщение об ошибке ввода

	call dopust			;Проверка допустимости вводимых символов
	cmp bh, flag_err  	;Сравним bh и flag_err
	je inErr         	;Если равен 1 сообщение об ошибке ввода
	
	call AscToBin 	    ;Преобразование строки в число
	inc di
	inc di
	pop cx
	loop inputVal
	jmp searchMinMax
	
inErr:   		
	print inputError	
	jmp check
	
;******************************* Нахождение миниамльного и максимального элементов *******************************
searchMinMax:
	mov cx, siz				;cx - размер массива
	mov si, offset number
	xor ax, ax
	
searchLoop:					;для поиска минимальных и максимальных
	mov ax,[si]				;элементов была принята нулевая гипотеза:
							;max = -29999 (минимальный  из возможных элементов)
							;min =  29999 (максимальный из возможных элементов)
	
findMax:
	cmp ax, max				;если найден элемент больше текущего значения max,
	jg 	foundMax			;то переход к перезаписи max
	
findMin:
	cmp ax, min				;если найден элемент меньше текущего значения min,
	jl foundMin			    ;то переход к перезаписи min
	jmp nextVal				;иначе переход к следующему элементу
	
foundMax:
	mov max, ax				;перезапись max элемента
	jmp findMin

foundMin:
	mov min,ax				;перезапись min элемента
	
nextVal:
	inc si
	inc si
	loop searchLoop
		
	
;*********************************** Нахождение суммы положительных элементов ************************************
searchPosSum:
	mov cx, siz				;cx - размер массива
	mov si, offset number
	xor ax, ax
sumPositive:
	mov ax,[si]
	cmp ax, 0				;сравнение с 0
	jl negative				;если число меньше то переход
	add sumPos,ax			;иначе сложение с переменной
	jo overFlowErr     		;если переполнение, то переход   
negative:		
	inc si
	inc si
	loop sumPositive
		
		
		
;******************************** Нахождение произведения отрицательных элементов ********************************
searchNegMul:
	mov cx, siz				;cx - размер массива
	mov si, offset number
	
	mov ax, 1				;для циклического умножения заносим 1
							;поскольку умножение всегда просиходит с регистром ax
	
minusEl:
	mov bx,[si]
	cmp bx, 00h
	jge plusEl				;если положительный элемент - идем дальше
	imul bx					;иначе умножаем
	jo overFlowErr 			;проверяем на переполнение
	
plusEl:
	inc si
	inc si
	loop minusEl
	
	mov mulNeg, ax			;заносим значение в переменную 



;******************** Нахождение разницы суммы положительных и разницы отрицательных элементов *******************
searchDiffSumMul:		;поскольку вычитание (sub) работает по принципу:
	mov ax, sumPos		;  <Приемник>=<Приемник>-<Источник>
	sub ax, mulNeg      ;чтобы не испортить результаты предудыщих вычислений
	mov diffRez, ax		;мы одну из перенных переносим в отдельный регистр, где и сохраним
						;результат, а затем запишем значение регистра в переменную
	
	
	
	
	jmp resOutput		;переход к выводу результатов 
	
	
;******************** Вывод ошибок ********************
overFlowErr:		
	print overflow  ;вывод сообщения о переполнении
	jmp progend
zero:
	print divByZeroError ;вывод сообщения о делении на ноль
	jmp progend
		
				
		
;***************************************** Вывод полученных результатов ******************************************
resOutput:		
	print sumPosText
	mov ax, sumPos
	call BinToAsc
	print out_str

	mov cx,6			;очистка буфера вывода
	xor si,si
clear1:		
	mov [out_str+si],' '
	inc si
	loop clear1

	print mulNegText
	mov ax,mulNeg	
	call BinToAsc
	print out_str

	mov cx,6			;очистка буфера вывода
	xor si,si
clear2:		
	mov [out_str+si],' '
	inc si
	loop clear2

	print diffResText
	mov ax,diffRez	
	call BinToAsc
	print out_str
	
	mov cx,6			;очистка буфера вывода
	xor si,si
		
clear3:		
	mov [out_str+si],' '
	inc si
	loop clear3

	print maxElText
	mov ax,max	
	call BinToAsc
	print out_str
		
	mov cx,6			;очистка буфера вывода
	xor si,si
	
clear4:		
	mov [out_str+si],' '
	inc si
	loop clear4

	print minElText
	mov ax,min	
	call BinToAsc
	print out_str
		
	mov cx,6			;очистка буфера вывода
	xor si,si

	jmp progend
progend:	
		mov ax,4c00h
		int 21h
	
	
	
	
;****************************************************
;* Проверка диапазона вводимых чисел -29999,+29999	*
;* Аргументы:										*
;* 		Буфер ввода - stroka						*
;* 													*
;* Результат:										*
;* 		bh - флаг ошибки ввода						*
;****************************************************
DIAPAZON PROC
    xor bh, bh
	xor si, si
	
	cmp kol, 05h 	; Если ввели менее 5 символов, проверим их допустимость
	jb dop
		
	cmp stroka, 2dh 	; Eсли ввели 5 или более символов проверим является ли первый минусом
	jne plus 	; Eсли 1 символ не минус, проверим число символов
	
	cmp kol, 06h 	; Eсли первый - минус и символов меньше 6 проверим допустимость символов 
	jb dop        
	
	inc si		; Иначе проверим первую цифру
	jmp first

plus:   
	cmp kol,6	; Bведено 6 символов и первый - не минус 
	je error1	; Oшибка
	
first:  
	cmp stroka[si], 32h	; Cравним первый символ с '2'
	jna dop		; Eсли первый <= '2' - проверим допустимость символов
	
error1:
	mov bh, flag_err	; Иначе bh = flag_err
	
dop:	
	ret
DIAPAZON ENDP



;****************************************************
;* Проверка допустимости вводимых символов			*
;* Аргументы:										*
;* 		Буфер ввода - stroka						*
;*		si - номер символа в строке					*
;* 													*
;* Результат:										*
;* 		bh - флаг ошибки ввода						*
;****************************************************
DOPUST PROC

	xor bh, bh
    xor si, si
	xor ah, ah
	xor ch, ch
	
	mov cl, kol	; В (cl) количество введенных символов
	
m11:	
	mov al, [stroka + si] 	; B (al) - первый символ
	cmp al, 2dh	; Является ли символ минусом
	jne testdop	; Если не минус - проверка допустимости
	cmp si, 00h	; Если минус  - является ли он первым символом
	jne error2	; Если минус не первый - ошибка
	jmp m13
	
testdop:
	cmp al, 30h	;Является ли введенный символ цифрой
	jb error2
	cmp al, 39h
	ja error2
	
m13: 	
	inc si
	loop m11
	jmp m14
	
error2:	
	mov bh, flag_err	; При недопустимости символа bh = flag_err
	
m14:	
	ret
DOPUST ENDP



;****************************************************
;* ASCII to number									*
;* Аргументы:										*
;* 		B cx количество введенных символов			*
;*		B bx - номер символа начиная с последнего 	*
;* 													*
;* Результат:										*
;* 		Буфер чисел - number						*
;*		B di - номер числа в массиве				*
;****************************************************
AscToBin PROC
	xor ch, ch
	mov cl, kol
	xor bh, bh
	mov bl, cl
	dec bl
	mov si, 01h  ; В si вес разряда
	
n1:	
	mov al, [stroka + bx]
	xor ah, ah
	cmp al, 2dh	; Проверим знак числа
	je otr	; Eсли число отрицательное
	sub al,	30h
	mul si
	add [number + di], ax
	mov ax, si
	mov si, 10
	mul si
	mov si, ax
	dec bx
	loop n1
	jmp n2
otr:	
	neg [number + di]	; Представим отрицательное число в дополнительном коде
	
n2:	
	ret
AscToBin ENDP



;****************************************************
;* Number to ASCII									*
;* Аргументы:										*
;* 		Число передается через ax					*
;* 													*
;* Результат:										*
;* 		Буфер чисел - out_str						*
;****************************************************
BinToAsc PROC
	xor si, si
	add si, 05h
	mov bx, 0Ah
	push ax
	cmp ax, 00h
	jnl mm1
	neg ax
	
mm1:	
	cwd
	idiv bx
	add dl,30h
	mov [out_str + si], dl
	dec si
	cmp ax, 00h
	jne mm1
	pop ax
	cmp ax, 00h
	jge mm2
	mov [out_str + si], 2dh
	
mm2:	
	ret
BinToAsc ENDP
      
	  
c1 ENDS	
end start