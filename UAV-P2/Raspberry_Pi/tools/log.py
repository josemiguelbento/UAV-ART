from math import sin, cos


class log():
    def __init__(self, fileName):
        self.fileName = fileName
        self._file = open(fileName, 'w+')
        self._file.write(
            'Time(s) pitch(rad) yaw(rad) roll(rad) pitchspeed(rad/s) yawspeed(rad/s) rollspeed(rad/s) pn(m) pe(m) alt[MSL](m) vnorth[NED](m/s) veast[NED](m/s) vdown[NED](m/s) xacc(m/s^2) yacc(m/s^2) zacc(m/s^2) IAS(m/s) AOA() Sideslip() RCch1() RCch2() RCch3() RCch4()\n')

    def addEntry(self, state, delta, sensors, time):
        text = '{time} {theta} {psi} {phi} {q} {r} {p} {pn} {pe} {h} {vNorth} {vEast} {vDown} {xacc} {yacc} {zacc} {Va} {alpha} {beta} {delta_a} {delta_e} {delta_t} {delta_r}'
        text = text.format(time=time, theta=sensors.pitch, psi=sensors.yaw, phi=sensors.roll, q=sensors.gyro_y, r=sensors.gyro_z, p=sensors.gyro_x, pn=sensors.gps_n,
                           pe=sensors.gps_e, h=sensors.gps_h, vNorth=sensors.vx, vEast=sensors.vy,
                           vDown=sensors.vz, xacc=sensors.accel_x, yacc=sensors.accel_y, zacc=sensors.accel_z, Va=sensors.va, alpha=0, beta=0, delta_a=delta.aileron,
                           delta_e=delta.elevator, delta_t=delta.throttle, delta_r=delta.rudder)
        self._file.write(text + '\n')

    def closeLog(self):
        self._file.close()
