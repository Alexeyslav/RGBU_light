������ ������������ ��� ���������� ����������� RGBU �������� http://github.com/Alexeyslav/RGBU_light .
������������ � ������� �������������� ����������� COM-����� �� �������� 115200 ���

������� �������� �� Delphi7 � ������� ��������� ��������������� ���������� Aled ��� ����������� ��������� ����������� � Digit ����������� � ���������.

����������:

RGBU_console - ��������� � �������� ���������� RGBU-������

    ���������� ��������� �������������� ������ ������ � �������� ����� ������ �� ������� ���������� � ����� ����.
    ����� �255 �������������� ��� ����������������� - �� ����� ������ �� �������(����� ������� ��������� ������) ��������� ��� ������ ������������.
    ��� ������� ������ �����

RGBU_controller - ���������� �������� �������� �� ���� RGBU-�������
    ��������� ������ � ����� pattern.txt ������ ������� �������� ������������ ����� ��������� ������� �� ���� ��������� ���.
    ����� ������:
    - ��� ������ ������������ � ������� ";" �������� �������������
    - ������ ������ ������������
    - ��������� ������ ����������� �������� ";"
    - ������ ����������� �������� "," � ���������� �� ����� 4-�
    - ������� ������� ������ - ����� ����� �� 0 �� 255, ��������� ������ ������������������ ����� � ���� $hh ��� hh - 16-������ �����.
      ����� ������ ����� ������ �������������� � 0.
    - �� ������ ������ ����������� ������ ������ � 8-� �������� �������� ������ �������� ������ 1..8.

������ ����������� �����:

;     =1=      ;      =2=      ;      =3=      ;      =4=      ;      =5=      ;      =6=      ;      =7=      ;      =8=      ;     =16=
  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0
128,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0
  0,  0,  0,255;128,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0
  0,  0,  0,  0;  0,  0,  0,255;128,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0
  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,255;128,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0
  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,255;128,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0
  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,255;128,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0;  0,  0,  0,  0
