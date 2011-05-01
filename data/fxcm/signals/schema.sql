DROP TABLE IF EXISTS SignalAlerts;
DROP TABLE IF EXISTS Signals;

CREATE TABLE Signals (
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    Direction enum('long','short') NOT NULL,
    Description VARCHAR(250) NOT NULL,
    Timeframe VARCHAR(6) NOT NULL,
    MaxLoadedItems SMALLINT UNSIGNED NOT NULL,
    StartDelta VARCHAR(15) NOT NULL DEFAULT '2 days ago',
    Period VARCHAR(15) NOT NULL,
    Definition TEXT NOT NULL,
    PriceIndicator TEXT NOT NULL,
    PRIMARY KEY (ID,Direction)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

CREATE TABLE SignalAlerts (
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    Symbol VARCHAR(10) NOT NULL,
    SignalID INT UNSIGNED NOT NULL,
    CreateDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ValidTill DATETIME NULL,
    DetectedOn DATETIME NULL,
    PRIMARY KEY (ID),
    CONSTRAINT SignalAlerts_Signals FOREIGN KEY (SignalID) REFERENCES Signals(ID) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=INNODB DEFAULT CHARSET=utf8;


INSERT INTO Signals (Direction, Description, Timeframe, MaxLoadedItems, StartDelta, Period, Definition, PriceIndicator) VALUES
('short', '55 day low breakout', 'day', 200, '2 days ago', '1 hour', 'crossoverdown(low,previous(min(low,55),1)) AND min(previous(low,1),18) > previous(min(low,55),1)', 'previous(min(low,55),1)'),
('long', '55 day high breakout', 'day', 200, '2 days ago', '1 hour', 'crossoverup(high,previous(max(high,55),1)) AND max(previous(high,1),18) < previous(max(high,55),1)', 'previous(max(high,55),1)');
