import QtQml

QtObject {
    property int threshold: 240
    property int accumulatedDelta: 0

    signal volumeStep(int direction)

    function handleWheel(delta) {
        if (delta === 0)
            return;

        if (accumulatedDelta !== 0 && Math.sign(accumulatedDelta) !== Math.sign(delta))
            accumulatedDelta = 0;

        accumulatedDelta += delta;
        if (Math.abs(accumulatedDelta) < threshold)
            return;

        const direction = accumulatedDelta > 0 ? 1 : -1;
        accumulatedDelta -= direction * threshold;
        volumeStep(direction);
    }
}
