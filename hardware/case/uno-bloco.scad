// =====================================================================
//  Uno bloco: chassi impresso do S20 FE Console (conceito v0)
//
//  Quatro peças impressas, todas sem suporte:
//    base     placa de baixo + 4 colunas; a ventoinha de 80 mm fica dentro
//    bandeja  onde a placa do celular, a subplaca e os módulos encaixam
//    ponte    barra com mola que aperta o dissipador contra o SoC
//    pes      4 pés presos pelos parafusos da ventoinha
//
//  Coordenadas: X da esquerda para a direita, Y da frente (0) para trás (100),
//  Z para cima. As posições estão escritas "na planta", como nos desenhos da
//  placa-base (x da esquerda, y de trás para a frente), e Y() converte.
//
//  Tudo marcado com MEDIR é estimativa: confira na sua peça antes de imprimir.
//  As medidas da placa do celular vêm do layout do SM-G781B (mesmo chassi).
// =====================================================================

parte = "montagem"; // [montagem, base, bandeja, ponte, pes]
$fn = 48;

// ---------------------------------------------------------------- bloco
L = 100;                 // largura e profundidade do bloco
function Y(y) = L - y;   // y da planta (de trás para a frente) -> Y do OpenSCAD

// ---------------------------------------------------------------- pilha de alturas
pe_h = 6;                // pés: vão por onde o ar entra por baixo
base_t = 2.5;            // placa de baixo
fan_lado = 80;
fan_h = 25;
fan_furo = 71.5;         // distância entre furos da ventoinha de 80 mm
fan_boca = 77;           // furo de entrada de ar na base
fan_c = [50, 50];        // centro da ventoinha na planta
fan_folga = 6;           // ventoinha -> dissipador (a ponte mora aqui)
dis = [38, 30, 18];      // dissipador do SoC, aletas para baixo (MEDIR)
pasta = 0.5;             // pasta ou pad entre SoC e dissipador
soc_h = 1.6;             // quanto a blindagem do SoC desce abaixo da placa (MEDIR)
espacador = 2.4;         // altura dos espaçadores da placa do celular (> blindagens)
deck_t = 3;              // espessura da bandeja
cel_t = 0.8;             // espessura da placa do celular

z_fan0 = pe_h + base_t;
z_fan1 = z_fan0 + fan_h;
z_dis0 = z_fan1 + fan_folga;
z_dis1 = z_dis0 + dis[2];
deck_top = z_dis1 + pasta + soc_h - espacador;
deck_bot = deck_top - deck_t;
z_cel0 = deck_top + espacador;          // face de baixo da placa do celular
z_cel1 = z_cel0 + cel_t;

// ---------------------------------------------------------------- parafusos
piloto_m2 = 1.6;
piloto_m3 = 2.6;         // M3 direto no plástico (ou 4.0 para inserto de latão)
passa_m3 = 3.4;
coluna = 8;              // colunas dos cantos da base
canto = 4;               // centro dos parafusos bandeja -> colunas

// ---------------------------------------------------------------- placa do celular
cel_off = [6, 32];       // onde fica o canto da placa do celular na planta
// contorno da placa (tela para baixo, visto de cima), tirado do layout
cel_contorno = [[62.65, 49.69], [59.83, 49.93], [59.2, 50.29], [51.54, 50.51], [40.41, 49.93], [39.9, 48.99],
    [39.9, 42.68], [40.67, 41.33], [40.67, 29.71], [39.83, 28.82], [33.19, 28.82], [32.25, 29.86],
    [25.0, 29.86], [24.37, 30.37], [24.3, 41.45], [24.95, 42.22], [27.68, 42.25], [28.36, 42.76],
    [28.43, 48.94], [28.09, 49.49], [23.24, 49.57], [22.83, 49.16], [22.46, 47.49], [19.13, 47.49],
    [18.26, 48.09], [18.17, 49.59], [17.49, 50.07], [16.35, 49.95], [16.26, 48.79], [15.32, 48.82],
    [15.1, 50.05], [13.46, 50.17], [10.17, 50.05], [9.93, 48.79], [9.01, 48.79], [8.99, 49.81],
    [8.65, 50.07], [7.39, 49.93], [6.86, 48.99], [4.09, 48.79], [3.05, 47.85], [2.59, 46.18],
    [0.49, 45.89], [0.0, 45.24], [0.1, 38.07], [0.75, 37.49], [2.52, 37.13], [3.26, 35.85],
    [3.39, 2.83], [4.57, 2.64], [5.12, 3.58], [9.74, 3.56], [10.24, 3.03], [10.32, 0.71],
    [11.02, 0.23], [56.78, 0.23], [57.6, 0.78], [63.69, 0.95], [63.98, 1.38], [63.98, 4.28],
    [62.14, 5.35], [61.69, 7.76], [57.58, 8.15], [51.66, 8.07], [51.47, 9.86], [50.14, 10.51],
    [50.12, 18.63], [49.66, 19.3], [48.47, 19.74], [48.45, 22.73], [47.46, 24.06], [47.46, 33.89],
    [48.72, 35.2], [48.89, 37.49], [51.2, 37.9], [51.61, 38.79], [52.44, 39.3], [52.63, 47.03],
    [53.11, 47.37], [60.12, 47.42], [62.46, 48.79]];
cel_poly = [for (p = cel_contorno) [p[0] + cel_off[0], Y(p[1] + cel_off[1])]];

janela = [13, 30.5, 53, 62.5];          // recorte do dissipador (x1, y1, x2, y2)
dis_c = [(janela[0] + janela[2]) / 2, (janela[1] + janela[3]) / 2];
soc_c = [33, 44];                       // centro do SoC na planta
// espaçadores nos furos da placa: x, y, diâmetro externo, furo piloto (MEDIR os furos)
espacadores = [[51.8, 69.0, 5.5, piloto_m3], [28.3, 75.2, 4.5, piloto_m2],
               [28.7, 64.8, 4.5, piloto_m2], [63.5, 38.4, 3.8, piloto_m2]];
// molas do canto (ANT7000...): confirmar no multímetro quais são as teclas
molas = [[64.35, 33.95], [68.2, 33.95], [64.35, 36.0], [68.4, 36.0], [66.35, 38.55]];
pads_molas = true;                      // ilha onde as molas encostam (fita de cobre + fio)
hdc = [17.2, 34.0, 34.4, 36.7];         // conector do flex C-to-C (lado de trás, para cima)
bat = [51.7, 35.3, 56.5, 37.8];         // conector da bateria SOC7000
pinos = [38, 24, 13];                   // dissipador de pinos atrás do SoC (MEDIR)
pinos_c = [33, 50.5];                   // longe do conector do flex

// ---------------------------------------------------------------- paredes
parede_t = 2.5;
parede_h = 14;
parede_tras = [8, 92];                  // x de começo e fim
parede_frente = [10, 92];

// ---------------------------------------------------------------- módulos de cima (encaixe)
// pos = canto de trás-esquerda da placa na planta; tam = [x, y, espessura]
sub_pos = [9, 2.6];   sub = [44, 23, 1.0];        // subplaca USB-C (MEDIR)
usb_x = sub_pos[0] + sub[0] / 2;                  // USB-C no meio da borda de trás
usb_z = deck_top + 2.0 + sub[2] / 2;
pcm_pos = [55, 18];   pcm = [34, 6, 1.2];         // plaquinha de proteção da bateria (MEDIR)
buck_pos = [76.5, 28]; buck = [22, 17, 1.6];      // step-down 5 V (MP1584)
mos_pos = [77.5, 48]; mos = [20, 15, 1.6];        // plaquinha dos MOSFETs (perfurada)
pico_pos = [75.5, 66]; pico = [23.5, 18, 1.0];    // RP2040-Zero, USB-C para a direita
capac = [[59.5, 9], [68.7, 9], [77.9, 9]];        // 3 capacitores de polímero
cap_d = 8; cap_h = 12;
p4_x = 88.5; p4_furo = 8;                         // jack P4 de painel na parede de trás (MEDIR)
furos_fio = [[96.5, 19], [92, 21.5], [71, 58]]; // 12 V p/ baixo, 4 V p/ cima, ventoinha e NTC
fio_d = 4.5;

// botões: plaquinha perfurada em pé atrás da parede da frente, com 3 tácteis 6x6
botoes_x = [44, 56, 68];
botao_z = 7;
perf = [41.5, 1.6, 12];
perf_y = 92.4;                                    // face de trás da plaquinha

// ---------------------------------------------------------------- módulos de baixo (parafusados)
// ficam pendurados embaixo da bandeja por espaçadores de nylon M3
xl_pos = [74, 36];  xl = [23, 54, 1.6];  xl_esp = 18;     // XL4015 (54 x 23 x 18 mm)
xl_furos = [[3, 3], [20, 51]];                            // MEDIR os furos do seu módulo
ina_pos = [72, 8];  ina = [20, 27, 1.6]; ina_esp = 10;    // INA226 (CJMCU-226, 20 x 27 mm)
ina_furos = [[2.5, 24.5], [17.5, 24.5]];                  // MEDIR

// ---------------------------------------------------------------- ponte do dissipador
ponte_furos = [[4, dis_c[1]], [61, dis_c[1]]];
ponte_l = 8;
ponte_t = 4;

antena = true;          // suporte para uma antena FPC colada (opcional)

// =====================================================================
//  ajudantes
// =====================================================================
module ret(x1, y1, x2, y2, z1, z2)
    translate([x1, Y(y2), z1]) cube([x2 - x1, y2 - y1, z2 - z1]);

module cil(x, y, d, z1, z2, fn = 0)
    translate([x, Y(y), z1]) cylinder(d = d, h = z2 - z1, $fn = fn > 0 ? fn : $fn);

// furo ao longo de Y (atravessa as paredes de trás e da frente)
module furo_y(x, y1, y2, z, d)
    translate([x, Y(y1), z]) rotate([90, 0, 0]) cylinder(d = d, h = y2 - y1);

// furo M3 escareado vindo de cima: a cabeça fica rente à bandeja
module escareado(x, y) {
    cil(x, y, passa_m3, deck_bot - 1, deck_top + 1);
    translate([x, Y(y), deck_top - 1.8]) cylinder(d1 = passa_m3, d2 = 6.6, h = 1.81);
    cil(x, y, 6.6, deck_top, deck_top + 5);   // espaço para a cabeça passar pelas bordas
}

// bolsa de encaixe: borda, degrau onde a placa apoia e travinhas
// abre = [esquerda, direita, trás, frente]: lados sem borda
module bolsa(pos, tam, degrau = 1.5, abre = [false, false, false, false], travas_y = false) {
    r = 1.2; g = 0.25;
    x1 = pos[0] - g; x2 = pos[0] + tam[0] + g;
    y1 = pos[1] - g; y2 = pos[1] + tam[1] + g;
    zt = deck_top - 0.01;
    zd = deck_top + degrau;
    zp = zd + tam[2] + 0.2;
    zh = zp + 0.6;
    ya = abre[2] ? y1 : y1 - r;
    yb = abre[3] ? y2 : y2 + r;
    xa = abre[0] ? x1 : x1 - r;
    xb = abre[1] ? x2 : x2 + r;
    if (!abre[0]) ret(x1 - r, ya, x1, yb, zt, zh);
    if (!abre[1]) ret(x2, ya, x2 + r, yb, zt, zh);
    if (!abre[2]) ret(xa, y1 - r, xb, y1, zt, zh);
    if (!abre[3]) ret(xa, y2, xb, y2 + r, zt, zh);
    if (!abre[0]) ret(x1, y1, x1 + 1, y2, zt, zd);
    if (!abre[1]) ret(x2 - 1, y1, x2, y2, zt, zd);
    if (!abre[2]) ret(x1, y1, x2, y1 + 1, zt, zd);
    if (!abre[3]) ret(x1, y2 - 1, x2, y2, zt, zd);
    ym = (y1 + y2) / 2; xm = (x1 + x2) / 2;
    if (!abre[0]) ret(x1, ym - 3, x1 + 0.5, ym + 3, zp, zh);
    if (!abre[1]) ret(x2 - 0.5, ym - 3, x2, ym + 3, zp, zh);
    if (travas_y && !abre[2]) ret(xm - 3, y1, xm + 3, y1 + 0.5, zp, zh);
    if (travas_y && !abre[3]) ret(xm - 3, y2 - 0.5, xm + 3, y2, zp, zh);
}

// =====================================================================
//  peças impressas
// =====================================================================
module base() {
    difference() {
        union() {
            ret(0, 0, L, L, pe_h, z_fan0);
            for (x = [0, L - coluna], y = [0, L - coluna])
                ret(x, y, x + coluna, y + coluna, z_fan0 - 0.01, deck_bot);
        }
        cil(fan_c[0], fan_c[1], fan_boca, pe_h - 1, z_fan0 + 1, 120);
        for (dx = [-1, 1], dy = [-1, 1])
            cil(fan_c[0] + dx * fan_furo / 2, fan_c[1] + dy * fan_furo / 2, 4.4, pe_h - 1, z_fan0 + 1);
        for (x = [canto, L - canto], y = [canto, L - canto])
            cil(x, y, piloto_m3, deck_bot - 14, deck_bot + 1);
    }
    // grade de proteção na boca de entrada
    intersection() {
        cil(fan_c[0], fan_c[1], fan_boca + 0.5, pe_h, z_fan0, 120);
        union() {
            difference() {
                cil(fan_c[0], fan_c[1], 42, pe_h, z_fan0, 96);
                cil(fan_c[0], fan_c[1], 37.2, pe_h - 1, z_fan0 + 1, 96);
            }
            ret(fan_c[0] - 1.2, 0, fan_c[0] + 1.2, L, pe_h, z_fan0);
            ret(0, fan_c[1] - 1.2, L, fan_c[1] + 1.2, pe_h, z_fan0);
        }
    }
}

module pes() {
    for (dx = [-1, 1], dy = [-1, 1]) {
        x = fan_c[0] + dx * fan_furo / 2;
        y = fan_c[1] + dy * fan_furo / 2;
        difference() {
            cil(x, y, 14, 0, pe_h);
            cil(x, y, 4.4, -1, pe_h + 1);
            cil(x, y, 8.2, -1, 3);      // rebaixo para a cabeça do parafuso
        }
    }
}

module ventilacao() {
    zonas = [[14, 66, 44, 81], [47, 66, 67, 81], [57, 52, 66, 64]];
    difference() {
        for (z = zonas)
            intersection() {
                ret(z[0], z[1], z[2], z[3], deck_bot - 1, deck_top + 1);
                for (y = [z[1] : 5 : z[3]]) ret(z[0], y, z[2], y + 2.4, deck_bot - 1, deck_top + 1);
            }
        for (e = espacadores) cil(e[0], e[1], e[2] + 4, deck_bot - 2, deck_top + 2);
    }
}

module trilhos() {
    // dois trilhos com ranhura: a plaquinha dos botões desliza de cima para baixo
    xa = (botoes_x[0] + botoes_x[2]) / 2 - perf[0] / 2;
    xb = xa + perf[0];
    y1 = perf_y - 2; y2 = perf_y + perf[1] + 2;
    zt = deck_top + perf[2] + 1;
    difference() {
        union() {
            ret(xa - 4, y1, xa + 1, y2, deck_top - 0.01, zt);
            ret(xb - 1, y1, xb + 4, y2, deck_top - 0.01, zt);
        }
        ret(xa - 1, perf_y - 0.1, xb + 1, perf_y + perf[1] + 0.1, deck_top + 0.4, zt + 1);
    }
}

module bandeja() {
    difference() {
        union() {
            ret(0, 0, L, L, deck_bot, deck_top);
            ret(parede_tras[0], 0, parede_tras[1], parede_t, deck_top - 0.01, deck_top + parede_h);
            ret(parede_frente[0], L - parede_t, parede_frente[1], L, deck_top - 0.01, deck_top + parede_h);
            bolsa(sub_pos, sub, 2.0, [false, false, true, false]);
            bolsa(pcm_pos, pcm, 1.5);
            bolsa(buck_pos, buck, 1.5);
            bolsa(mos_pos, mos, 2.0);
            bolsa(pico_pos, pico, 1.5, [false, true, false, false], true);
            difference() {
                union() for (c = capac) cil(c[0], c[1], cap_d + 2.8, deck_top - 0.01, deck_top + 4);
                for (c = capac) cil(c[0], c[1], cap_d + 0.4, deck_top, deck_top + 5);
            }
            for (e = espacadores) cil(e[0], e[1], e[2], deck_top - 0.01, deck_top + espacador);
            for (p = ponte_furos)
                difference() {
                    cil(p[0], p[1], 8, deck_top - 0.01, deck_top + 1);
                    cil(p[0], p[1], 6.2, deck_top + 0.5, deck_top + 2);   // centraliza a mola
                }
            trilhos();
            if (antena) ret(0, 52, 2, 82, deck_top - 0.01, deck_top + 16);
            if (pads_molas)
                difference() {
                    ret(62.5, 32.8, 70.2, 40, deck_top - 0.01, deck_top + 1.2);
                    cil(espacadores[3][0], espacadores[3][1], espacadores[3][2] + 0.6, deck_top, deck_top + 2);
                }
        }
        ret(janela[0], janela[1], janela[2], janela[3], deck_bot - 1, deck_top + 1);
        ventilacao();
        for (x = [canto, L - canto], y = [canto, L - canto])
            cil(x, y, passa_m3, deck_bot - 1, deck_top + 1);
        for (e = espacadores) cil(e[0], e[1], e[3], deck_bot - 1, deck_top + espacador + 1);
        for (p = ponte_furos) cil(p[0], p[1], passa_m3, deck_bot - 1, deck_top + 3);
        for (f = furos_fio) cil(f[0], f[1], fio_d, deck_bot - 1, deck_top + 3);
        for (h = xl_furos) escareado(xl_pos[0] + h[0], xl_pos[1] + h[1]);
        for (h = ina_furos) escareado(ina_pos[0] + h[0], ina_pos[1] + h[1]);
        // parede de trás: USB-C da subplaca e jack P4
        ret(usb_x - 6.5, -1, usb_x + 6.5, parede_t + 0.5, usb_z - 3.5, usb_z + 3.5);
        furo_y(p4_x, -1, parede_t + 1, deck_top + 8, p4_furo);
        // parede da frente: botões
        for (bx = botoes_x) furo_y(bx, L - parede_t - 1, L + 1, deck_top + botao_z, 4);
    }
}

module ponte() {
    x1 = ponte_furos[0][0] - 4; x2 = ponte_furos[1][0] + 4;
    y = ponte_furos[0][1];
    difference() {
        ret(x1, y - ponte_l / 2, x2, y + ponte_l / 2, z_dis0 - ponte_t, z_dis0);
        for (p = ponte_furos) {
            cil(p[0], p[1], passa_m3, z_dis0 - ponte_t - 1, z_dis0 + 1);
            cil(p[0], p[1], 6.4, z_dis0 - ponte_t - 1, z_dis0 - ponte_t + 2.6, 6);   // porca M3 presa
        }
    }
}

// =====================================================================
//  peças de referência (compradas ou do celular), só para a montagem
// =====================================================================
module ref_ventoinha() {
    translate([fan_c[0], Y(fan_c[1]), z_fan0]) {
        difference() {
            translate([-fan_lado / 2, -fan_lado / 2, 0]) cube([fan_lado, fan_lado, fan_h]);
            translate([0, 0, -1]) cylinder(d = 76, h = fan_h + 2, $fn = 96);
            for (dx = [-1, 1], dy = [-1, 1]) {
                translate([dx * fan_furo / 2, dy * fan_furo / 2, -1]) cylinder(d = 4.3, h = fan_h + 2);
                translate([dx * fan_furo / 2, dy * fan_furo / 2, 4.5]) cylinder(d = 10, h = fan_h - 9);
            }
        }
        translate([0, 0, 1]) cylinder(d = 32, h = fan_h - 2, $fn = 64);
        for (i = [0 : 6]) rotate([0, 0, i * 360 / 7])
            translate([15, 0, fan_h / 2]) rotate([28, 0, 0]) translate([0, -7, -0.6]) cube([22, 14, 1.2]);
    }
}

module ref_dissipador() {
    x0 = dis_c[0] - dis[0] / 2; y0 = dis_c[1] - dis[1] / 2;
    ret(x0, y0, x0 + dis[0], y0 + dis[1], z_dis1 - 3, z_dis1);
    for (i = [0 : 11]) {
        x = x0 + i * (dis[0] - 1.2) / 11;
        ret(x, y0, x + 1.2, y0 + dis[1], z_dis0, z_dis1 - 2.99);
    }
}

module ref_pinos() {
    z0 = z_cel1 + 1.6 + pasta;
    x0 = pinos_c[0] - pinos[0] / 2; y0 = pinos_c[1] - pinos[1] / 2;
    ret(x0, y0, x0 + pinos[0], y0 + pinos[1], z0, z0 + 3);
    for (i = [0 : 9], j = [0 : 5])
        cil(x0 + 2.6 + i * 3.64, y0 + 2.5 + j * 3.8, 2, z0 + 2.99, z0 + pinos[2], 12);
}

module ref_celular() translate([0, 0, z_cel0]) linear_extrude(cel_t) polygon(cel_poly);

module ref_cel_soc() ret(soc_c[0] - 7.5, soc_c[1] - 7.5, soc_c[0] + 7.5, soc_c[1] + 7.5, z_cel0 - soc_h, z_cel0);

module ref_cel_blindagem() ret(16, 39, 50, 61, z_cel1, z_cel1 + 1.6);

module ref_cel_conectores() {
    ret(hdc[0], hdc[1], hdc[2], hdc[3], z_cel1 - 0.01, z_cel1 + 1.0);
    ret(bat[0], bat[1], bat[2], bat[3], z_cel1 - 0.01, z_cel1 + 1.0);
    for (m = molas) cil(m[0], m[1], 1.2, z_cel0 - 1.2, z_cel0 + 0.01, 16);
}

module ref_subplaca() {
    z = deck_top + 2.0;
    ret(sub_pos[0], sub_pos[1], sub_pos[0] + sub[0], sub_pos[1] + sub[1], z, z + sub[2]);
}

module ref_sub_conectores() {
    z = deck_top + 2.0;
    ret(usb_x - 4.5, sub_pos[1] - 0.6, usb_x + 4.5, sub_pos[1] + 6.8, z + sub[2] / 2 - 1.65, z + sub[2] / 2 + 1.65);
    ret(16.8, 16, 34.8, 19.5, z + sub[2] - 0.01, z + sub[2] + 1.0);
}

module ref_flex() {
    zc = z_cel1 + 1.0;
    pts = [[35.0, zc + 0.15], [31.0, zc + 2.5], [27.5, zc + 7], [21.5, zc + 8.5],
           [16.0, zc + 6], [15.0, zc + 2.5], [17.5, deck_top + 2 + sub[2] + 1.15]];
    for (i = [0 : len(pts) - 2])
        hull() {
            ret(16.8, pts[i][0] - 0.15, 34.8, pts[i][0] + 0.15, pts[i][1] - 0.15, pts[i][1] + 0.15);
            ret(16.8, pts[i + 1][0] - 0.15, 34.8, pts[i + 1][0] + 0.15, pts[i + 1][1] - 0.15, pts[i + 1][1] + 0.15);
        }
}

module ref_xl4015() {
    zb = deck_bot - xl_esp - xl[2];
    zt = zb + xl[2];
    x0 = xl_pos[0]; y0 = xl_pos[1];
    ret(x0, y0, x0 + xl[0], y0 + xl[1], zb, zt);
    cil(x0 + 11.5, y0 + 25, 12, zt - 0.01, zt + 7, 32);           // indutor
    cil(x0 + 12, y0 + 10, 8, zt - 0.01, zt + 13, 24);             // capacitores
    cil(x0 + 8, y0 + 45, 8, zt - 0.01, zt + 13, 24);
    ret(x0 + 15, y0 + 36, x0 + 21, y0 + 43, zt - 0.01, zt + 5);   // trimpots
}

module ref_ina226() {
    zb = deck_bot - ina_esp - ina[2];
    zt = zb + ina[2];
    x0 = ina_pos[0]; y0 = ina_pos[1];
    ret(x0, y0, x0 + ina[0], y0 + ina[1], zb, zt);
    ret(x0 + 7, y0 + 6, x0 + 13, y0 + 9.5, zt - 0.01, zt + 0.7);  // shunt
    ret(x0 + 7.5, y0 + 13, x0 + 12.5, y0 + 16, zt - 0.01, zt + 1);
}

module ref_buck() {
    z = deck_top + 1.5;
    ret(buck_pos[0], buck_pos[1], buck_pos[0] + buck[0], buck_pos[1] + buck[1], z, z + buck[2]);
    ret(buck_pos[0] + 8, buck_pos[1] + 5, buck_pos[0] + 14, buck_pos[1] + 11, z + buck[2] - 0.01, z + buck[2] + 3.2);
}

module ref_mosfets() {
    z = deck_top + 2.0;
    ret(mos_pos[0], mos_pos[1], mos_pos[0] + mos[0], mos_pos[1] + mos[1], z, z + mos[2]);
    for (i = [0 : 3])
        ret(mos_pos[0] + 2.5 + i * 4.3, mos_pos[1] + 5, mos_pos[0] + 5.4 + i * 4.3, mos_pos[1] + 8,
            z + mos[2] - 0.01, z + mos[2] + 1.1);
}

module ref_pico() {
    z = deck_top + 1.5;
    zt = z + pico[2];
    ret(pico_pos[0], pico_pos[1], pico_pos[0] + pico[0], pico_pos[1] + pico[1], z, zt);
    ret(pico_pos[0] + 7, pico_pos[1] + 5.5, pico_pos[0] + 14, pico_pos[1] + 12.5, zt - 0.01, zt + 0.9);
    ret(pico_pos[0] + pico[0] - 6.4, pico_pos[1] + 4.5, pico_pos[0] + pico[0] + 1, pico_pos[1] + 13.5, zt - 0.01, zt + 3.2);
}

module ref_pcm() {
    z = deck_top + 1.5;
    ret(pcm_pos[0], pcm_pos[1], pcm_pos[0] + pcm[0], pcm_pos[1] + pcm[1], z, z + pcm[2]);
}

module ref_capacitores() for (c = capac) cil(c[0], c[1], cap_d, deck_top, deck_top + cap_h, 32);

module ref_botoes() {
    xa = (botoes_x[0] + botoes_x[2]) / 2 - perf[0] / 2;
    zc = deck_top + botao_z;
    ret(xa, perf_y, xa + perf[0], perf_y + perf[1], deck_top + 0.4, deck_top + perf[2] + 0.4);
    for (bx = botoes_x) ret(bx - 3, perf_y + perf[1], bx + 3, perf_y + perf[1] + 3.5, zc - 3, zc + 3);
}

module ref_botoes_hastes() for (bx = botoes_x) furo_y(bx, perf_y + perf[1] + 3.5, L + 3.5, deck_top + botao_z, 3.5);

module ref_p4() {
    zc = deck_top + 8;
    furo_y(p4_x, parede_t, parede_t + 14, zc, 10);
    furo_y(p4_x, -0.01, parede_t + 0.01, zc, p4_furo - 0.2);
    furo_y(p4_x, -2, 0, zc, 12);
}

module ref_antena() ret(2, 53, 2.4, 81, deck_top + 2, deck_top + 14);

// ---------------------------------------------------------------- parafusos, molas e espaçadores
// bandeja -> colunas: 4x M3 x 10
module ref_paraf_bandeja()
    for (x = [canto, L - canto], y = [canto, L - canto]) {
        cil(x, y, 5.5, deck_top, deck_top + 3);
        cil(x, y, 3, deck_bot - 7, deck_top);
    }

// ponte: 2x M3 x 30 com mola por cima e porca presa na ponte
module ref_paraf_ponte()
    for (p = ponte_furos) {
        cil(p[0], p[1], 5.5, deck_top + 5, deck_top + 8);
        cil(p[0], p[1], 3, z_dis0 - ponte_t + 0.5, deck_top + 5);
    }

// ventoinha: 4x M4 x 20 pelo pé, pela base e pela aba de baixo da ventoinha
module ref_paraf_ventoinha()
    for (dx = [-1, 1], dy = [-1, 1]) {
        x = fan_c[0] + dx * fan_furo / 2; y = fan_c[1] + dy * fan_furo / 2;
        cil(x, y, 7, 0.4, 3);
        cil(x, y, 4, 3, z_fan0 + 4.5 + 3.2);
    }

// placa do celular: M3 no furo grande, M2 nos outros
module ref_paraf_celular()
    for (e = espacadores) {
        cil(e[0], e[1], e[3] == piloto_m3 ? 5.5 : 3.8, z_cel1, z_cel1 + 1.4);
        cil(e[0], e[1], e[3] == piloto_m3 ? 3 : 2, deck_top - 1.5, z_cel1);
    }

// XL4015 e INA226: M3 escareado de cima (cima) e M3 por baixo da placa (baixo)
module ref_paraf_mod(cima = true)
    for (m = [[xl_pos, xl_furos, xl_esp, xl[2]], [ina_pos, ina_furos, ina_esp, ina[2]]])
        for (h = m[1]) {
            x = m[0][0] + h[0]; y = m[0][1] + h[1];
            if (cima) {
                translate([x, Y(y), deck_top - 1.8]) cylinder(d1 = 3, d2 = 6, h = 1.8);
                cil(x, y, 3, deck_bot - 2.5, deck_top - 1.79);
            } else {
                cil(x, y, 5.5, deck_bot - m[2] - m[3] - 2, deck_bot - m[2] - m[3]);
                cil(x, y, 3, deck_bot - m[2] - m[3] - 0.01, deck_bot - m[2] + 2.5);
            }
        }

module ref_parafusos() {
    ref_paraf_bandeja(); ref_paraf_ponte(); ref_paraf_ventoinha(); ref_paraf_celular();
    ref_paraf_mod(true); ref_paraf_mod(false);
}

module ref_porcas_ponte() for (p = ponte_furos) cil(p[0], p[1], 6.2, z_dis0 - ponte_t, z_dis0 - ponte_t + 2.4, 6);
module ref_porcas_ventoinha() for (dx = [-1, 1], dy = [-1, 1])
    cil(fan_c[0] + dx * fan_furo / 2, fan_c[1] + dy * fan_furo / 2, 7.6, z_fan0 + 4.5, z_fan0 + 4.5 + 3.2, 6);
module ref_porcas() { ref_porcas_ponte(); ref_porcas_ventoinha(); }

module ref_molas() for (p = ponte_furos)
    difference() { cil(p[0], p[1], 6, deck_top + 1, deck_top + 5); cil(p[0], p[1], 3.6, deck_top, deck_top + 6); }

module ref_espacadores() {
    for (m = [[xl_pos, xl_furos, xl_esp], [ina_pos, ina_furos, ina_esp]])
        for (h = m[1]) cil(m[0][0] + h[0], m[0][1] + h[1], 5.6, deck_bot - m[2], deck_bot, 6);
}

// =====================================================================
//  saída
// =====================================================================
module montagem() {
    color("#E8E4DA") base();
    color("#D9D4C7") pes();
    color("#2F6FB0") bandeja();
    color("#2F6FB0") ponte();
    color("#3A3A3A", 0.9) ref_ventoinha();
    color("#B8BEC4") ref_dissipador();
    color("#B8BEC4") ref_pinos();
    color("#1F4A39") ref_celular();
    color("#202020") ref_cel_soc();
    color("#A9AEB3") ref_cel_blindagem();
    color("#C9A13B") ref_cel_conectores();
    color("#1F4A39") ref_subplaca();
    color("#C9A13B") ref_sub_conectores();
    color("#E09A3E") ref_flex();
    color("#1E5AA8") ref_xl4015();
    color("#6B3FA0") ref_ina226();
    color("#1E5AA8") ref_buck();
    color("#2E7D32") ref_mosfets();
    color("#222222") ref_pico();
    color("#2E7D32") ref_pcm();
    color("#5B4636") ref_capacitores();
    color("#2E7D32") ref_botoes();
    color("#111111") ref_botoes_hastes();
    color("#333333") ref_p4();
    color("#8E6CC7") ref_antena();
    color("#555555") ref_parafusos();
    color("#888888") ref_porcas();
    color("#C0C0C0") ref_molas();
    color("#F5F5F0") ref_espacadores();
}

if (parte == "montagem") montagem();
if (parte == "base") base();
if (parte == "bandeja") bandeja();
if (parte == "ponte") ponte();
if (parte == "pes") pes();
// peças de referência, uma por vez (usado para gerar o 3D)
if (parte == "ref_ventoinha") ref_ventoinha();
if (parte == "ref_dissipador") ref_dissipador();
if (parte == "ref_pinos") ref_pinos();
if (parte == "ref_celular") ref_celular();
if (parte == "ref_cel_soc") ref_cel_soc();
if (parte == "ref_cel_blindagem") ref_cel_blindagem();
if (parte == "ref_cel_conectores") ref_cel_conectores();
if (parte == "ref_subplaca") ref_subplaca();
if (parte == "ref_sub_conectores") ref_sub_conectores();
if (parte == "ref_flex") ref_flex();
if (parte == "ref_xl4015") ref_xl4015();
if (parte == "ref_ina226") ref_ina226();
if (parte == "ref_buck") ref_buck();
if (parte == "ref_mosfets") ref_mosfets();
if (parte == "ref_pico") ref_pico();
if (parte == "ref_pcm") ref_pcm();
if (parte == "ref_capacitores") ref_capacitores();
if (parte == "ref_botoes") ref_botoes();
if (parte == "ref_botoes_hastes") ref_botoes_hastes();
if (parte == "ref_p4") ref_p4();
if (parte == "ref_antena") ref_antena();
if (parte == "ref_paraf_bandeja") ref_paraf_bandeja();
if (parte == "ref_paraf_ponte") ref_paraf_ponte();
if (parte == "ref_paraf_ventoinha") ref_paraf_ventoinha();
if (parte == "ref_paraf_celular") ref_paraf_celular();
if (parte == "ref_paraf_mod_cima") ref_paraf_mod(true);
if (parte == "ref_paraf_mod_baixo") ref_paraf_mod(false);
if (parte == "ref_porcas_ponte") ref_porcas_ponte();
if (parte == "ref_porcas_ventoinha") ref_porcas_ventoinha();
if (parte == "ref_molas") ref_molas();
if (parte == "ref_espacadores") ref_espacadores();
