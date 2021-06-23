from datetime import datetime
import matplotlib.pyplot as plt
import requests
from dateutil.relativedelta import relativedelta

"""

Функция генерирует спиcок дат в требуемом формате 
для api https://www.cbr-xml-daily.ru/

"""


def create_date_list_api_format(start_date, end_date):
    start_date_f = datetime.strptime(start_date, '%d.%m.%y')
    end_date_f = datetime.strptime(end_date, '%d.%m.%y')

    # формируем список дат
    dates_list = []

    d = start_date_f
    while d <= end_date_f:
        year = d.year
        month = str(d.strftime('%m'))
        day = str(d.strftime('%d'))
        date_f = f'{year}/{month}/{day}'
        dates_list.append(date_f)

        d += relativedelta(days=1)

    return dates_list




"""

Функция получает даты в формате 'dd.mm.yy',валюту
и возвращает кортеж со списками для оси X (даты) и
оси Y (курс)

"""


def get_course_data(start_date, end_date, currency):
    d_list = create_date_list_api_format(start_date, end_date)
    course_dict = dict.fromkeys(d_list)

    """Получаем от api курсы на дату"""
    for d in course_dict:
        url_f = f'https://www.cbr-xml-daily.ru/archive/{d}/daily_json.js'

        r = requests.get(url_f)
        data = r.json()
        try:
            rate = data['Valute'][currency]['Value']
            course_dict[d] = rate
        except:
            pass

        dates = []
        rates = []

        for k in course_dict:
            dates.append(k)
            rates.append(course_dict[k])

        for k, v in enumerate(rates):
            if v is None:
                target_key = k - 1
                if target_key >= 0:
                    rates[k] = rates[k - 1]

    return (dates, rates)




usd_course = get_course_data('01.04.21', '20.04.21', 'USD')
#eur_course = get_course_data('01.04.21', '20.04.21', 'EUR')
#gbp_course = get_course_data('01.04.21', '20.04.21', 'GBP')

plt.figure(figsize=(10, 7))
plt.grid()
plt.xlabel("Дата")
plt.ylabel("руб.")

plt.plot(usd_course[0], usd_course[1]
         #,eur_course[0], eur_course[1]
         #,gbp_course[0], gbp_course[1]
         )

plt.xticks(rotation=90)
plt.show()

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    pass


