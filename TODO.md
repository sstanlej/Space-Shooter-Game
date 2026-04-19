# TO DO lista pomysły
1. Statystyki ataku, szybkosci i szybkosci ataku wyswietlac w ui overlayu zamiast w panelu ulepszen
2. Zastapic serduszka zielonymi lampkami
3. Zaimplementowac nowe typu clusterow: W ksztalcie klucza ptakow i inne
    - Dodac rozne rozmiary clusterow i czestotliwosc zalezna od difficulty
4. Ulepszenia w sklepie:
    - Regeneracja punktu życia (“RegenerationUpgrade”)
    - Tarcza która chroni przed określoną ilością obrażeń (“ShieldUpgrade”)
    - Parametr Rarity - rzadkość, im większa tym rzadziej występuje w sklepie
5. Zbalansować spawnowanie przeciwników i ulepszenia w sklepie
    - Zbalansować UFO

- [ ] dodac final bossa
- [ ] dodac ekran wygranej i mozliwosc kontynuowania
- [ ] dodac ekran glowny z przyskiskiem start, best scorem i przyciskiem wyjscia
- [ ] dodac “oomph” - animacje, screen shake
- [ ] game over screen - animacja tla zaczyna powli zwalniac az sie zatrzyma
- [ ] dodac ulepszanie statku
- [ ] dodac system fal (waves), tak jak w Shutshimi, po kazdej fali rozwija sie panel ulepszenia statku
- [ ] skalowalnosc difficulty

Nowy system:
- Parametr difficulty, który zaczyna od 1 i zwiększa się z każdą falą lub co kilka fal
    - Po zabiciu bossa difficulty zwiększa się o kilka punktów naraz
    - Difficulty wpływa na (widełki):
        - Ilość przeciwników w danej fali
        - Punkty życia przeciwników
        - Przerwę między przeciwnikami
        - Typ przeciwników
        - Częstotliwość aktywacji stanu specjalnego przeciwnika
        - Prędkość przeciwników
- Przeciwnicy spawnują się w losowych punktach na ekranie zamiast w kształcie sinusoidy
    - Funkcja get_random_points() w pattern generatorze, która przyjmuje liczbę punktów, minimalny i maksymalny odstęp między przeciwnikami i zwraca listę losowych punktów

Pattern generator:
- Klasa Pattern: lista współrzędnych punktów w których będą się spawnować przeciwnicy
    - size() - ilość punktów
    - add(pattern) - dodanie drugiego pat ternu
    - Cluster to pattern
- Oddzielna lista współrzędnych x i y, lista wielkości przerw między x-ami (gaps), funkcja clusterify(x_index, amount, gap) która zmienia punkt o zadanym indeksie w cluster o zadanych parametrach


Przeciwnicy:
Każdy przeciwnik ma stan podstawowy oraz stan specjalny (rzadki, aktywowany co jakiś czas losowo)
- Meteor
    - Stan podstawowy: leci w stronę gracza, trajektoria prosta
    - Stan specjalny: leci pod kątem, jeśli zderzy się z innym meteorem to rozbija się na 4 mniejsze i szybsze meteory
    - (Jeśli zderzy się z innym obiektem niż meteor lub gracz (np. z ufo) to w zadanym promieniu następuje eksplozja zadająca obrażenia graczowi)
    - Jeśli zderzy się z UFO to jest szansa że kosmita wypadnie ze statku, będzie kręcić się wokół własnej osi i lecieć prosto w stronę gracza
    - Za meteorem pojawiają się cząsteczki dymu
- UFO
    - Stan podstawowy: leci w stronę gracza, trajektoria w kształcie zygzaka
    - Stan specjalny: strzela w stronę gracza laserem zadającym obrażenia